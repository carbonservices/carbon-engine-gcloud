#include "TrayManager.h"
#include "system/WindowsService.h"

#include <QApplication>
#include <QCoreApplication>
#include <QFile>
#include <QIcon>
#include <QProcess>
#include <QStyle>
#include <QThread>

TrayManager::TrayManager(QObject* parent)
    : QObject(parent)
{
    m_trayIcon = new QSystemTrayIcon(this);

    // Attempt to load application icon from app directory or fallback to system icon
    QString iconPath = QCoreApplication::applicationDirPath() + "/app.ico";
    QIcon icon(iconPath);
    if (icon.isNull()) {
        icon = QApplication::style()->standardIcon(QStyle::SP_ComputerIcon);
    }
    m_trayIcon->setIcon(icon);

    m_trayMenu = new QMenu();

    m_openClientAction = m_trayMenu->addAction("Open Carbon ESG");
    connect(m_openClientAction, &QAction::triggered, this, &TrayManager::openClient);

    m_trayMenu->addSeparator();

    m_statusAction = m_trayMenu->addAction("Service Status: Checking...");
    m_statusAction->setEnabled(false);

    m_startAction = m_trayMenu->addAction("Start Service");
    connect(m_startAction, &QAction::triggered, this, &TrayManager::startService);

    m_stopAction = m_trayMenu->addAction("Stop Service");
    connect(m_stopAction, &QAction::triggered, this, &TrayManager::stopService);

    m_restartAction = m_trayMenu->addAction("Restart Service");
    connect(m_restartAction, &QAction::triggered, this, &TrayManager::restartService);

    m_trayMenu->addSeparator();

    m_quitAction = m_trayMenu->addAction("Quit Service Manager");
    connect(m_quitAction, &QAction::triggered, qApp, &QCoreApplication::quit);

    m_trayIcon->setContextMenu(m_trayMenu);
    connect(m_trayIcon, &QSystemTrayIcon::activated, this, &TrayManager::onTrayActivated);

    m_pollTimer = new QTimer(this);
    connect(m_pollTimer, &QTimer::timeout, this, &TrayManager::updateStatus);
    m_pollTimer->start(2500);

    updateStatus();
    m_trayIcon->show();
}

void TrayManager::updateStatus()
{
    bool installed = WindowsService::isServiceInstalled();
    bool running = WindowsService::isServiceRunning();

    if (!installed) {
        m_statusAction->setText("Service: Not Registered");
        m_startAction->setEnabled(false);
        m_stopAction->setEnabled(false);
        m_restartAction->setEnabled(false);
        m_trayIcon->setToolTip("Carbon Engine: Not Registered");
    } else if (running) {
        m_statusAction->setText("Service Status: Running");
        m_startAction->setEnabled(false);
        m_stopAction->setEnabled(true);
        m_restartAction->setEnabled(true);
        m_trayIcon->setToolTip("Carbon Engine Service: Running");
    } else {
        m_statusAction->setText("Service Status: Stopped");
        m_startAction->setEnabled(true);
        m_stopAction->setEnabled(false);
        m_restartAction->setEnabled(false);
        m_trayIcon->setToolTip("Carbon Engine Service: Stopped");
    }
}

void TrayManager::startService()
{
    QString msg;
    bool ok = WindowsService::startService(msg);
    m_trayIcon->showMessage(
        "Carbon Engine",
        msg,
        ok ? QSystemTrayIcon::Information : QSystemTrayIcon::Warning,
        4000
    );
    updateStatus();
}

void TrayManager::stopService()
{
    QString msg;
    bool ok = WindowsService::stopService(msg);
    m_trayIcon->showMessage(
        "Carbon Engine",
        msg,
        ok ? QSystemTrayIcon::Information : QSystemTrayIcon::Warning,
        4000
    );
    updateStatus();
}

void TrayManager::restartService()
{
    QString stopMsg, startMsg;
    WindowsService::stopService(stopMsg);
    QThread::msleep(800);
    bool ok = WindowsService::startService(startMsg);
    m_trayIcon->showMessage(
        "Carbon Engine",
        ok ? "Service restarted successfully." : QString("Restart failed: %1").arg(startMsg),
        ok ? QSystemTrayIcon::Information : QSystemTrayIcon::Warning,
        4000
    );
    updateStatus();
}

void TrayManager::openClient()
{
    QString clientPath = QCoreApplication::applicationDirPath() + "/carbon-engine-client.exe";
    if (QFile::exists(clientPath)) {
        QProcess::startDetached(clientPath, {});
    } else {
        m_trayIcon->showMessage(
            "Carbon ESG",
            "Desktop UI executable (carbon-engine-client.exe) not found.",
            QSystemTrayIcon::Warning,
            3000
        );
    }
}

void TrayManager::onTrayActivated(QSystemTrayIcon::ActivationReason reason)
{
    if (reason == QSystemTrayIcon::DoubleClick || reason == QSystemTrayIcon::Trigger) {
        openClient();
    }
}

