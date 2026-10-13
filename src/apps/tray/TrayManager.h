#pragma once

#include <QObject>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QTimer>

class TrayManager : public QObject {
    Q_OBJECT

public:
    explicit TrayManager(QObject* parent = nullptr);
    ~TrayManager() override = default;

public slots:
    void updateStatus();
    void startService();
    void stopService();
    void restartService();
    void openClient();
    void onTrayActivated(QSystemTrayIcon::ActivationReason reason);

private:
    QSystemTrayIcon* m_trayIcon{nullptr};
    QMenu* m_trayMenu{nullptr};
    QAction* m_openClientAction{nullptr};
    QAction* m_statusAction{nullptr};
    QAction* m_startAction{nullptr};
    QAction* m_stopAction{nullptr};
    QAction* m_restartAction{nullptr};
    QAction* m_quitAction{nullptr};
    QTimer* m_pollTimer{nullptr};
};

