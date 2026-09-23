#pragma once

#include <QImage>
#include <QRect>
#include <QString>

class QWindow;

// macOS window/screen glue. Native_mac.mm / Platform_stub.cpp.
namespace native {

struct NotchInfo {
    QRect screen;          // screen geometry in Qt global coordinates
    int notchWidth = 0;    // points
    int notchHeight = 0;   // = menu bar height on a notched display
    bool hasNotch = false;
};
// The built-in display with a camera housing; otherwise the menu-bar
// screen with a simulated notch.
NotchInfo notchInfo();

// Borderless non-activating panel above the menu bar, on every Space and
// over full-screen apps. Call before and after the first show().
void configureWindow(QWindow* window);
// Sets the frame directly (Cocoa would otherwise keep it below the menu bar).
void placeWindow(QWindow* window, const QRect& qtGeometry);
// true = clicks go through to whatever is underneath.
void setClickThrough(QWindow* window, bool clickThrough);
// Keyboard/click focus without activating the app (non-activating panel).
void takeFocus(QWindow* window);
void releaseFocus(QWindow* window);

bool isMouseButtonDown();
// Changes whenever a drag-and-drop session starts anywhere in the system.
qint64 dragPasteboardChangeCount();

QImage fileIcon(const QString& path, int pixels);
void openFile(const QString& path);
void revealInFinder(const QString& path);
void playSound(const QString& name);

bool launchAtLoginEnabled();
bool setLaunchAtLogin(bool enable, QString* error);

} // namespace native
