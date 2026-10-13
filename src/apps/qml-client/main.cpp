#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QtWebEngineQuick>

int main(int argc, char *argv[])
{
    QtWebEngineQuick::initialize();

    QGuiApplication app(argc, argv);
    app.setApplicationName("Carbon ESG");
    app.setOrganizationName("Carbon Services");
    app.setApplicationDisplayName("Carbon ESG");
#ifdef CARBON_ENGINE_VERSION
    app.setApplicationVersion(CARBON_ENGINE_VERSION);
#else
    app.setApplicationVersion("1.0.0");
#endif

    QQuickStyle::setStyle("Basic");

    QIcon appIcon(":/CarbonEngineClient/logo.png");
    if (appIcon.isNull())
    {
        appIcon = QIcon(":/qt/qml/CarbonEngineClient/logo.png");
    }
    if (appIcon.isNull())
    {
        appIcon = QIcon("logo.png");
    }
    app.setWindowIcon(appIcon);

    QQmlApplicationEngine engine;
    engine.loadFromModule("CarbonEngineClient", "Main");

    if (engine.rootObjects().isEmpty())
    {
        return -1;
    }

    return app.exec();
}