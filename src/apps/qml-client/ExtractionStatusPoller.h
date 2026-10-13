#ifndef EXTRACTION_STATUS_POLLER_H
#define EXTRACTION_STATUS_POLLER_H

#include "ApiClientBase.h"

// Qt
#include <QQmlEngine>
#include <QTimer>
#include <QSet>
#include <QStringList>

class ExtractionStatusPoller : public ApiClientBase
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString engineMode READ engineMode NOTIFY cloudTelemetryUpdated)
    Q_PROPERTY(QString activeModel READ activeModel NOTIFY cloudTelemetryUpdated)
    Q_PROPERTY(QString pacingStatus READ pacingStatus NOTIFY cloudTelemetryUpdated)
    Q_PROPERTY(qint64 lastLatencyMs READ lastLatencyMs NOTIFY cloudTelemetryUpdated)
    Q_PROPERTY(int lastPromptTokens READ lastPromptTokens NOTIFY cloudTelemetryUpdated)
    Q_PROPERTY(int lastCandidateTokens READ lastCandidateTokens NOTIFY cloudTelemetryUpdated)
    Q_PROPERTY(bool isRateLimited READ isRateLimited NOTIFY rateLimitChanged)
    Q_PROPERTY(QString rateLimitError READ rateLimitError NOTIFY rateLimitChanged)
    Q_PROPERTY(QString rateLimitedModel READ rateLimitedModel NOTIFY rateLimitChanged)
    Q_PROPERTY(QString rateLimitedSection READ rateLimitedSection NOTIFY rateLimitChanged)
    Q_PROPERTY(QString rateLimitType READ rateLimitType NOTIFY rateLimitChanged)

public:
    explicit ExtractionStatusPoller(QObject *parent = nullptr);
    Q_INVOKABLE void startPolling(int jobId);
    Q_INVOKABLE void stopPolling();
    Q_INVOKABLE void resolveRateLimit(const QString &action, const QString &newModel = QString());

    QString engineMode() const { return _engineMode; }
    QString activeModel() const { return _activeModel; }
    QString pacingStatus() const { return _pacingStatus; }
    qint64 lastLatencyMs() const { return _lastLatencyMs; }
    int lastPromptTokens() const { return _lastPromptTokens; }
    int lastCandidateTokens() const { return _lastCandidateTokens; }
    bool isRateLimited() const { return _isRateLimited; }
    QString rateLimitError() const { return _rateLimitError; }
    QString rateLimitedModel() const { return _rateLimitedModel; }
    QString rateLimitedSection() const { return _rateLimitedSection; }
    QString rateLimitType() const { return _rateLimitType; }

signals:
    void completed();
    void cancelled();
    void failed(const QString &reason);
    void progressUpdated(int currentStep, int totalSteps, const QString &groupLabel, double progressPct);
    void missingMetricsReceived(const QString &groupLabel, const QStringList &missingKeys);
    void cloudTelemetryUpdated();
    void rateLimitTriggered(const QString &error, const QString &model, const QString &section, const QString &type);
    void rateLimitChanged();

private:
    void poll();

    static constexpr int PollIntervalMs = 1000;

    QTimer _timer;
    int _jobId = -1;
    QSet<QString> _reportedMissingSections;
    int _lastStep{-1};
    QString _lastGroup;
    QString _engineMode{EngineMode::Offline};
    QString _activeModel{Models::LocalGemmaName};
    QString _pacingStatus{"IDLE"};
    qint64 _lastLatencyMs{0};
    int _lastPromptTokens{0};
    int _lastCandidateTokens{0};
    bool _isRateLimited{false};
    QString _rateLimitError;
    QString _rateLimitedModel;
    QString _rateLimitedSection;
    QString _rateLimitType{"INFERENCE"};
    Logger _log{"QmlClient.ExtractionStatusPoller"};
};

#endif // EXTRACTION_STATUS_POLLER_H
