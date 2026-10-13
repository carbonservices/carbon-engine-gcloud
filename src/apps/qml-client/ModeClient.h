#ifndef MODE_CLIENT_H
#define MODE_CLIENT_H

#include "ApiClientBase.h"

#include <QQmlEngine>
#include <QString>
#include <QStringList>

class ModeClient : public ApiClientBase
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool cloudEnabled READ cloudEnabled WRITE setCloudEnabled NOTIFY modeChanged)
    Q_PROPERTY(QString apiKey READ apiKey WRITE setApiKey NOTIFY apiKeyChanged)
    Q_PROPERTY(QString cloudModel READ cloudModel WRITE setCloudModel NOTIFY cloudModelChanged)
    Q_PROPERTY(QStringList availableModels READ availableModels NOTIFY availableModelsChanged)
    Q_PROPERTY(QString embeddingModel READ embeddingModel WRITE setEmbeddingModel NOTIFY embeddingModelChanged)
    Q_PROPERTY(QStringList availableEmbeddingModels READ availableEmbeddingModels NOTIFY availableEmbeddingModelsChanged)
    Q_PROPERTY(QString disclaimer READ disclaimer NOTIFY disclaimerChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(bool isTesting READ isTesting NOTIFY isTestingChanged)
    Q_PROPERTY(bool testSuccess READ testSuccess NOTIFY testResultChanged)
    Q_PROPERTY(qint64 testLatencyMs READ testLatencyMs NOTIFY testResultChanged)
    Q_PROPERTY(QString testError READ testError NOTIFY testResultChanged)
    Q_PROPERTY(bool inferenceTestSuccess READ inferenceTestSuccess NOTIFY testResultChanged)
    Q_PROPERTY(bool embeddingTestSuccess READ embeddingTestSuccess NOTIFY testResultChanged)
    Q_PROPERTY(qint64 embeddingTestLatencyMs READ embeddingTestLatencyMs NOTIFY testResultChanged)
    Q_PROPERTY(int embeddingDim READ embeddingDim NOTIFY testResultChanged)
    Q_PROPERTY(QString inferenceTestError READ inferenceTestError NOTIFY testResultChanged)
    Q_PROPERTY(QString embeddingTestError READ embeddingTestError NOTIFY testResultChanged)

public:
    explicit ModeClient(QObject *parent = nullptr);

    bool cloudEnabled() const { return _cloudEnabled; }
    void setCloudEnabled(bool enabled);

    QString apiKey() const { return _apiKey; }
    void setApiKey(const QString &key);

    QString cloudModel() const { return _cloudModel; }
    void setCloudModel(const QString &model);

    QString embeddingModel() const { return _embeddingModel; }
    void setEmbeddingModel(const QString &model);

    QStringList availableModels() const { return _availableModels; }
    QStringList availableEmbeddingModels() const { return _availableEmbeddingModels; }
    QString disclaimer() const { return _disclaimer; }
    QString statusMessage() const { return _statusMessage; }

    bool isTesting() const { return _isTesting; }
    bool testSuccess() const { return _testSuccess; }
    qint64 testLatencyMs() const { return _testLatencyMs; }
    QString testError() const { return _testError; }
    bool inferenceTestSuccess() const { return _inferenceTestSuccess; }
    bool embeddingTestSuccess() const { return _embeddingTestSuccess; }
    qint64 embeddingTestLatencyMs() const { return _embeddingTestLatencyMs; }
    int embeddingDim() const { return _embeddingDim; }
    QString inferenceTestError() const { return _inferenceTestError; }
    QString embeddingTestError() const { return _embeddingTestError; }

    Q_INVOKABLE void fetchMode();
    Q_INVOKABLE void saveSettings(bool cloudEnabled, const QString &apiKey, const QString &cloudModel, const QString &embeddingModel = QString());
    Q_INVOKABLE void testConnection();
    Q_INVOKABLE void fetchAvailableModels(const QString &apiKey = QString());

signals:
    void modeChanged();
    void apiKeyChanged();
    void cloudModelChanged();
    void availableModelsChanged();
    void embeddingModelChanged();
    void availableEmbeddingModelsChanged();
    void statusMessageChanged();
    void isTestingChanged();
    void testResultChanged();
    void settingsSaved();
    void disclaimerChanged();

private:
    bool _cloudEnabled{false};
    QString _apiKey;
    QString _cloudModel{Models::CloudDefaultModel};
    QStringList _availableModels{Models::CloudDefaultModel};
    QString _embeddingModel{Models::CloudDefaultEmbeddingModel};
    QStringList _availableEmbeddingModels{Models::CloudDefaultEmbeddingModel};
    QString _disclaimer;
    QString _statusMessage;

    bool _isTesting{false};
    bool _testSuccess{false};
    qint64 _testLatencyMs{0};
    QString _testError;
    bool _inferenceTestSuccess{false};
    bool _embeddingTestSuccess{false};
    qint64 _embeddingTestLatencyMs{0};
    int _embeddingDim{0};
    QString _inferenceTestError;
    QString _embeddingTestError;

    Logger _log{"QmlClient.ModeClient"};
};

#endif // MODE_CLIENT_H
