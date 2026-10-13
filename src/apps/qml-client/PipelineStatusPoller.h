#ifndef PIPELINE_STATUS_POLLER_H
#define PIPELINE_STATUS_POLLER_H

#include "ApiClientBase.h"

// Qt
#include <QQmlEngine>
#include <QTimer>
#include <QJsonArray>

class PipelineStatusPoller : public ApiClientBase
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool isRateLimited READ isRateLimited NOTIFY rateLimitChanged)
    Q_PROPERTY(QString rateLimitError READ rateLimitError NOTIFY rateLimitChanged)
    Q_PROPERTY(QString rateLimitedModel READ rateLimitedModel NOTIFY rateLimitChanged)
    Q_PROPERTY(QString rateLimitType READ rateLimitType NOTIFY rateLimitChanged)

public:
    explicit PipelineStatusPoller(QObject *parent = nullptr);
    Q_INVOKABLE void startPolling(int jobId);
    Q_INVOKABLE void stopPolling();
    Q_INVOKABLE void resolveRateLimit(const QString &action, const QString &newModel = QString());

    bool isRateLimited() const { return _isRateLimited; }
    QString rateLimitError() const { return _rateLimitError; }
    QString rateLimitedModel() const { return _rateLimitedModel; }
    QString rateLimitType() const { return _rateLimitType; }

signals:
    void completed();
    void cancelled();
    void failed(const QString &reason);
    void statusUpdated(const QString &status, const QJsonArray &documents);
    void rateLimitTriggered(const QString &error, const QString &model, const QString &type);
    void rateLimitChanged();

private:
    void poll();

    static constexpr int PollIntervalMs = 1000;

    QTimer _timer;
    int _jobId = -1;
    bool _isRateLimited{false};
    QString _rateLimitError;
    QString _rateLimitedModel;
    QString _rateLimitType{"EMBEDDING"};
    Logger _log{"QmlClient.PipelineStatusPoller"};
};

#endif // PIPELINE_STATUS_POLLER_H