// Non-macOS stubs so the project builds (and core tests run) elsewhere.

#include "Media.h"
#include "Native.h"

#include <QGuiApplication>
#include <QScreen>

namespace native {

NotchInfo notchInfo()
{
    NotchInfo info;
    if (const QScreen* s = QGuiApplication::primaryScreen())
        info.screen = s->geometry();
    info.notchWidth = 190;
    info.notchHeight = 32;
    return info;
}
void configureWindow(QWindow*) {}
void placeWindow(QWindow*, const QRect&) {}
void setClickThrough(QWindow*, bool) {}
void takeFocus(QWindow*) {}
void releaseFocus(QWindow*) {}
bool isMouseButtonDown() { return QGuiApplication::mouseButtons() != Qt::NoButton; }
qint64 dragPasteboardChangeCount() { return 0; }
bool dragHasFiles() { return false; }
bool isFullScreenActive() { return false; }
void setWindowShown(QWindow*, bool) {}
QImage fileIcon(const QString&, int) { return {}; }
void openFile(const QString&) {}
void revealInFinder(const QString&) {}
void playSound(const QString&) {}
bool launchAtLoginEnabled() { return false; }
bool setLaunchAtLogin(bool, QString* error)
{
    if (error)
        *error = QStringLiteral("Not supported on this platform");
    return false;
}

} // namespace native

namespace media {

bool systemAvailable() { return false; }
void querySystem(std::function<void(const Track&)> callback) { callback(Track {}); }
bool sendSystem(Command) { return false; }
Track queryScripted(const QString&) { return {}; }
void sendScripted(const QString&, Command) {}

} // namespace media
