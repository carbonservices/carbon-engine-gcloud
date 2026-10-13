#include "TrayManager.h"
#include "system/SingleInstanceGuard.h"

#include <QApplication>
#include <QMessageBox>

int main(int argc, char* argv[])
{
    SingleInstanceGuard guard("CarbonEngine_Tray_Mutex");
    if (!guard.isPrimary()) {
        // Another instance of the tray companion is already active in the taskbar notification area
        return 0;
    }

    QApplication app(argc, argv);
    app.setApplicationName("Carbon ESG Service Manager");
    app.setOrganizationName("Carbon Services");
#ifdef CARBON_ENGINE_VERSION
    app.setApplicationVersion(CARBON_ENGINE_VERSION);
#else
    app.setApplicationVersion("1.0.0");
#endif
    app.setQuitOnLastWindowClosed(false);

    if (!QSystemTrayIcon::isSystemTrayAvailable()) {
        QMessageBox::critical(nullptr, "Carbon ESG Service Manager", "System tray notification area is not supported on this platform.");
        return 1;
    }

    TrayManager trayManager;

    return app.exec();
}

