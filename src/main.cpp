#include "ImageStore.h"
#include "NotchController.h"

#include <QDebug>
#include <QDir>
#include <QGuiApplication>
#include <QLockFile>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QStandardPaths>

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("Isle"));
    QGuiApplication::setOrganizationName(QStringLiteral("Isle"));
    QGuiApplication::setOrganizationDomain(QStringLiteral("isle.app"));
    QGuiApplication::setApplicationVersion(QStringLiteral(PROJECT_VERSION_STRING));
    QGuiApplication::setQuitOnLastWindowClosed(false);

    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    QLockFile instanceLock(dataDir + QStringLiteral("/instance.lock"));
    if (!instanceLock.tryLock(100)) {
        qWarning() << "Isle is already running";
        return 0;
    }

    auto images = std::make_shared<ImageStore>();
    NotchController notch(images);

    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("img"), new ImageProvider(images));
    engine.setInitialProperties({ { QStringLiteral("notch"), QVariant::fromValue(&notch) } });
    engine.loadFromModule("Isle", "Main");

    auto* window = engine.rootObjects().isEmpty()
        ? nullptr
        : qobject_cast<QQuickWindow*>(engine.rootObjects().constFirst());
    if (!window) {
        qCritical() << "Isle: failed to load the QML window";
        return 1;
    }
    notch.attach(window);
    return app.exec();
}
