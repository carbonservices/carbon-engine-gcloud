#include "ModeClient.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSettings>

ModeClient::ModeClient(QObject *parent)
    : ApiClientBase(parent)
{
    fetchMode();
}

void ModeClient::setCloudEnabled(bool enabled)
{
    if (_cloudEnabled != enabled) {
        _cloudEnabled = enabled;
        emit modeChanged();
    }
}

void ModeClient::setApiKey(const QString &key)
{
    if (_apiKey != key) {
        _apiKey = key;
        emit apiKeyChanged();
    }
}

void ModeClient::setCloudModel(const QString &model)
{
    if (_cloudModel != model) {
        _cloudModel = model;
        emit cloudModelChanged();
    }
}

void ModeClient::setEmbeddingModel(const QString &model)
{
    if (_embeddingModel != model) {
        _embeddingModel = model;
        emit embeddingModelChanged();
    }
}

void ModeClient::fetchMode()
{
    QNetworkRequest req(endpoint(ApiRoutes::Mode));
    QNetworkReply *reply = network().get(req);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            _log.error(QString("Failed to fetch mode: %1").arg(reply->errorString()));
            _statusMessage = "Backend disconnected";
            emit statusMessageChanged();
            return;
        }

        auto doc = QJsonDocument::fromJson(reply->readAll());
        if (!doc.isObject()) return;

        QJsonObject obj = doc.object();
        _cloudEnabled = obj.value("cloud_enabled").toBool(false);
        _cloudModel = obj.value("cloud_model").toString(Models::CloudDefaultModel);

        if (obj.contains("api_key")) {
            QString key = obj.value("api_key").toString();
            if (!key.isEmpty()) {
                _apiKey = key;
                emit apiKeyChanged();
            }
        }

        if (obj.contains("cloud_embedding_model")) {
            _embeddingModel = obj.value("cloud_embedding_model").toString(Models::CloudDefaultEmbeddingModel);
            emit embeddingModelChanged();
        }

        if (obj.contains("available_models")) {
            QStringList models;
            for (const auto &v : obj.value("available_models").toArray()) {
                models.append(v.toString());
            }
            if (!models.isEmpty()) {
                _availableModels = models;
                emit availableModelsChanged();
            }
        }

        if (obj.contains("available_embedding_models")) {
            QStringList embModels;
            for (const auto &v : obj.value("available_embedding_models").toArray()) {
                embModels.append(v.toString());
            }
            if (!embModels.isEmpty()) {
                _availableEmbeddingModels = embModels;
                emit availableEmbeddingModelsChanged();
            }
        }

        if (obj.contains("disclaimer")) {
            QString disc = obj.value("disclaimer").toString();
            if (disc != _disclaimer) {
                _disclaimer = disc;
                emit disclaimerChanged();
            }
        }

        emit modeChanged();
        emit cloudModelChanged();
    });
}

void ModeClient::saveSettings(bool cloudEnabled, const QString &apiKey, const QString &cloudModel, const QString &embeddingModel)
{
    const QString targetEmbModel = embeddingModel.isEmpty() ? _embeddingModel : embeddingModel;

    QJsonObject reqObj;
    reqObj["cloud_enabled"] = cloudEnabled;
    reqObj["mode"] = cloudEnabled ? EngineMode::GCloud : EngineMode::Offline;
    if (!apiKey.isEmpty()) {
        reqObj["api_key"] = apiKey;
    }
    if (!cloudModel.isEmpty()) {
        reqObj["cloud_model"] = cloudModel;
    }
    if (!targetEmbModel.isEmpty()) {
        reqObj["cloud_embedding_model"] = targetEmbModel;
    }

    QNetworkRequest req = createJsonRequest(endpoint(ApiRoutes::Mode));
    QByteArray body = QJsonDocument(reqObj).toJson(QJsonDocument::Compact);
    QNetworkReply *reply = network().post(req, body);

    connect(reply, &QNetworkReply::finished, this, [this, reply, cloudEnabled, apiKey, cloudModel, targetEmbModel]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            _statusMessage = QString("Failed to save settings: %1").arg(reply->errorString());
            emit statusMessageChanged();
            return;
        }

        _cloudEnabled = cloudEnabled;
        _apiKey = apiKey;
        if (!cloudModel.isEmpty()) {
            _cloudModel = cloudModel;
        }
        if (!targetEmbModel.isEmpty()) {
            _embeddingModel = targetEmbModel;
        }

        auto doc = QJsonDocument::fromJson(reply->readAll());
        if (doc.isObject()) {
            QJsonObject obj = doc.object();
            _cloudEnabled = obj.value("cloud_enabled").toBool(_cloudEnabled);
            _cloudModel = obj.value("cloud_model").toString(_cloudModel);
            if (obj.contains("cloud_embedding_model")) {
                _embeddingModel = obj.value("cloud_embedding_model").toString(_embeddingModel);
            }
        }

        _statusMessage = "Settings saved successfully.";
        emit statusMessageChanged();
        emit apiKeyChanged();
        emit modeChanged();
        emit cloudModelChanged();
        emit embeddingModelChanged();
        emit settingsSaved();
    });
}

void ModeClient::testConnection()
{
    _isTesting = true;
    _testSuccess = false;
    _inferenceTestSuccess = false;
    _embeddingTestSuccess = false;
    _testLatencyMs = 0;
    _embeddingTestLatencyMs = 0;
    _embeddingDim = 0;
    _testError.clear();
    _inferenceTestError.clear();
    _embeddingTestError.clear();
    emit isTestingChanged();
    emit testResultChanged();

    QJsonObject reqObj;
    if (!_apiKey.isEmpty()) {
        reqObj["api_key"] = _apiKey;
    }
    if (!_cloudModel.isEmpty()) {
        reqObj["cloud_model"] = _cloudModel;
    }
    if (!_embeddingModel.isEmpty()) {
        reqObj["cloud_embedding_model"] = _embeddingModel;
    }

    QNetworkRequest req = createJsonRequest(endpoint(ApiRoutes::ConfigTest));
    QByteArray body = QJsonDocument(reqObj).toJson(QJsonDocument::Compact);
    QNetworkReply *reply = network().post(req, body);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        _isTesting = false;

        if (reply->error() != QNetworkReply::NoError) {
            _testSuccess = false;
            _inferenceTestSuccess = false;
            _embeddingTestSuccess = false;
            _testError = reply->errorString();
            emit isTestingChanged();
            emit testResultChanged();
            return;
        }

        auto doc = QJsonDocument::fromJson(reply->readAll());
        if (!doc.isObject()) {
            _testSuccess = false;
            _testError = "Invalid response from server";
            emit isTestingChanged();
            emit testResultChanged();
            return;
        }

        QJsonObject obj = doc.object();
        _testSuccess = obj.value("success").toBool(false);
        _inferenceTestSuccess = obj.value("inference_success").toBool(_testSuccess);
        _embeddingTestSuccess = obj.value("embedding_success").toBool(false);
        _testLatencyMs = obj.value("latency_ms").toInteger();
        _embeddingTestLatencyMs = obj.value("embedding_latency_ms").toInteger();
        _embeddingDim = obj.value("embedding_dim").toInt(0);
        _testError = obj.value("error").toString();
        _inferenceTestError = obj.value("inference_error").toString();
        _embeddingTestError = obj.value("embedding_error").toString();

        if (obj.contains("model")) {
            QString testedModel = obj.value("model").toString();
            if (!testedModel.isEmpty() && testedModel != _cloudModel) {
                _cloudModel = testedModel;
                emit cloudModelChanged();
            }
        }

        if (obj.contains("embedding_model")) {
            QString testedEmbModel = obj.value("embedding_model").toString();
            if (!testedEmbModel.isEmpty() && testedEmbModel != _embeddingModel) {
                _embeddingModel = testedEmbModel;
                emit embeddingModelChanged();
            }
        }

        if (obj.contains("available_models")) {
            QStringList models;
            for (const auto &v : obj.value("available_models").toArray()) {
                models.append(v.toString());
            }
            if (!models.isEmpty()) {
                _availableModels = models;
                emit availableModelsChanged();
            }
        }

        if (obj.contains("available_embedding_models")) {
            QStringList embModels;
            for (const auto &v : obj.value("available_embedding_models").toArray()) {
                embModels.append(v.toString());
            }
            if (!embModels.isEmpty()) {
                _availableEmbeddingModels = embModels;
                emit availableEmbeddingModelsChanged();
            }
        }

        emit isTestingChanged();
        emit testResultChanged();
    });
}

void ModeClient::fetchAvailableModels(const QString &apiKey)
{
    QString key = !apiKey.isEmpty() ? apiKey.trimmed() : _apiKey.trimmed();

    QJsonObject reqObj;
    if (!key.isEmpty()) {
        reqObj["api_key"] = key;
    }

    QNetworkRequest req = createJsonRequest(endpoint(ApiRoutes::Models));
    QByteArray body = QJsonDocument(reqObj).toJson(QJsonDocument::Compact);
    QNetworkReply *reply = network().post(req, body);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            _log.error(QString("Failed to fetch models from server: %1").arg(reply->errorString()));
            return;
        }

        auto doc = QJsonDocument::fromJson(reply->readAll());
        if (!doc.isObject()) return;

        QJsonObject obj = doc.object();
        if (obj.contains("available_models")) {
            QStringList genModels;
            for (const auto &v : obj.value("available_models").toArray()) {
                genModels.append(v.toString());
            }
            if (!genModels.isEmpty()) {
                _availableModels = genModels;
                emit availableModelsChanged();

                if (!_availableModels.contains(_cloudModel)) {
                    QString bestModel = _availableModels.first();
                    for (const auto &m : _availableModels) {
                        if (m.contains("flash", Qt::CaseInsensitive)) {
                            bestModel = m;
                            break;
                        }
                    }
                    _cloudModel = bestModel;
                    emit cloudModelChanged();
                }
            }
        }

        if (obj.contains("available_embedding_models")) {
            QStringList embModels;
            for (const auto &v : obj.value("available_embedding_models").toArray()) {
                embModels.append(v.toString());
            }
            if (!embModels.isEmpty()) {
                _availableEmbeddingModels = embModels;
                emit availableEmbeddingModelsChanged();

                if (!_availableEmbeddingModels.contains(_embeddingModel)) {
                    QString bestEmb = _availableEmbeddingModels.first();
                    for (const auto &m : _availableEmbeddingModels) {
                        if (m.contains("text-embedding-004", Qt::CaseInsensitive)) {
                            bestEmb = m;
                            break;
                        }
                    }
                    _embeddingModel = bestEmb;
                    emit embeddingModelChanged();
                }
            }
        }
    });
}
