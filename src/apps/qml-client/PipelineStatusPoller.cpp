#include "PipelineStatusPoller.h"

// Qt
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrlQuery>

PipelineStatusPoller::PipelineStatusPoller(QObject *parent) : ApiClientBase(parent)
{
    connect(&_timer, &QTimer::timeout, this, &PipelineStatusPoller::poll);
}

void PipelineStatusPoller::startPolling(int jobId)
{
    _jobId = jobId;
    _log.info(QString("Started polling job %1").arg(jobId));
    poll();
    _timer.start(PollIntervalMs);
}

void PipelineStatusPoller::stopPolling()
{
    _log.info(QString("Stopped polling job %1").arg(_jobId));
    _timer.stop();
    _jobId = -1;
}

void PipelineStatusPoller::poll()
{
    int polledJobId = _jobId;
    if (polledJobId < 0) {
        return;
    }

    QUrl url = endpoint(ApiRoutes::Jobs);
    QUrlQuery query;
    query.addQueryItem("job_id", QString::number(polledJobId));
    url.setQuery(query);

    QNetworkReply *reply = network().get(QNetworkRequest(url));
    connect(reply, &QNetworkReply::finished, this, [this, reply, polledJobId]()
    {
        reply->deleteLater();
        if (_jobId != polledJobId || _jobId < 0) {
            return;
        }
        if (reply->error() != QNetworkReply::NoError)
        {
            _log.error(QString("Poll failed for job %1: %2").arg(_jobId).arg(reply->errorString()));
            return;
        }

        auto doc = QJsonDocument::fromJson(reply->readAll());
        QJsonObject root = doc.object();
        QString status = root.value("status").toString();
        QJsonArray docs = root.value("documents").toArray();
        bool rateLimited = root.value("rate_limited").toBool(false);
        QString rateLimitError = root.value("rate_limit_error").toString();
        QString rateLimitedModel = root.value("rate_limited_model").toString();
        QString rateLimitType = root.value("rate_limit_type").toString("EMBEDDING");

        if (rateLimited != _isRateLimited || rateLimitError != _rateLimitError) {
            _isRateLimited = rateLimited;
            _rateLimitError = rateLimitError;
            _rateLimitedModel = rateLimitedModel;
            _rateLimitType = rateLimitType;
            emit rateLimitChanged();
            if (_isRateLimited) {
                emit rateLimitTriggered(_rateLimitError, _rateLimitedModel, _rateLimitType);
            }
        }

        _log.info(QString("Job %1 status: %2, %3 document(s)").arg(_jobId).arg(status).arg(docs.size()));

        emit statusUpdated(status, docs);

        if (status == JobStatus::Completed)
        {
            _timer.stop();
            emit completed();
        }
        else if (status == JobStatus::Failed)
        {
            _timer.stop();
            emit failed("Ingestion failed");
        }
        else if (status == JobStatus::Cancelled)
        {
            _timer.stop();
            emit cancelled();
        }
    });
}

void PipelineStatusPoller::resolveRateLimit(const QString &action, const QString &newModel)
{
    QJsonObject reqObj;
    reqObj["job_id"] = _jobId;
    reqObj["action"] = action;
    if (!newModel.isEmpty()) {
        reqObj["new_model"] = newModel;
    }

    QNetworkRequest req = createJsonRequest(endpoint(ApiRoutes::JobResolveRateLimit));
    QByteArray body = QJsonDocument(reqObj).toJson(QJsonDocument::Compact);
    QNetworkReply *reply = network().post(req, body);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            _log.error(QString("Failed to resolve job rate limit: %1").arg(reply->errorString()));
            return;
        }
        _isRateLimited = false;
        emit rateLimitChanged();
        poll();
    });
}
