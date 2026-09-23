// Compiled as Objective-C++ with ARC.
// Note: `template` and `class` are C++ keywords, so the matching Objective-C
// properties are used via message syntax ([obj setTemplate:], [X class]).

#include "Native.h"

#include <QWindow>

#import <AppKit/AppKit.h>
#import <ServiceManagement/ServiceManagement.h>

namespace {

NSWindow* nsWindowOf(QWindow* window)
{
    if (!window)
        return nil;
    NSView* view = (__bridge NSView*)reinterpret_cast<void*>(window->winId());
    return view.window;
}

CGFloat primaryScreenHeight()
{
    NSScreen* primary = NSScreen.screens.firstObject;
    return primary ? primary.frame.size.height : 0;
}

QRect toQt(NSRect r)
{
    return QRect(qRound(r.origin.x), qRound(primaryScreenHeight() - r.origin.y - r.size.height),
                 qRound(r.size.width), qRound(r.size.height));
}

NSRunningApplication* g_previousApp = nil;

} // namespace

namespace native {

NotchInfo notchInfo()
{
    NotchInfo info;
    NSScreen* target = nil;
    if (@available(macOS 12.0, *)) {
        for (NSScreen* screen in NSScreen.screens) {
            if (screen.safeAreaInsets.top > 0) {
                target = screen;
                break;
            }
        }
    }
    info.hasNotch = target != nil;
    if (!target)
        target = NSScreen.screens.firstObject;
    if (!target)
        return info;

    const NSRect frame = target.frame;
    info.screen = toQt(frame);

    if (info.hasNotch) {
        if (@available(macOS 12.0, *)) {
            const NSRect left = target.auxiliaryTopLeftArea;
            const NSRect right = target.auxiliaryTopRightArea;
            info.notchWidth = qRound(frame.size.width - left.size.width - right.size.width);
            info.notchHeight = qRound(target.safeAreaInsets.top);
        }
    }
    if (info.notchWidth <= 0) {
        info.hasNotch = false;
        info.notchWidth = 190;
        const CGFloat menuBar = NSMaxY(frame) - NSMaxY(target.visibleFrame);
        info.notchHeight = menuBar >= 20 ? qRound(menuBar) : 24;
    }
    return info;
}

void configureWindow(QWindow* window)
{
    NSWindow* w = nsWindowOf(window);
    if (!w)
        return;

    if ([w isKindOfClass:[NSPanel class]]) {
        NSPanel* panel = (NSPanel*)w;
        // Receives clicks without making Isle the active app, like Spotlight.
        panel.styleMask = panel.styleMask | NSWindowStyleMaskNonactivatingPanel;
        panel.becomesKeyOnlyIfNeeded = NO;
        panel.floatingPanel = YES;
    }
    w.level = NSMainMenuWindowLevel + 3;   // above the menu bar
    w.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces
                         | NSWindowCollectionBehaviorStationary
                         | NSWindowCollectionBehaviorFullScreenAuxiliary
                         | NSWindowCollectionBehaviorIgnoresCycle;
    w.hidesOnDeactivate = NO;
    w.hasShadow = NO;
    w.opaque = NO;
    w.backgroundColor = NSColor.clearColor;
    w.animationBehavior = NSWindowAnimationBehaviorNone;
}

void placeWindow(QWindow* window, const QRect& g)
{
    NSWindow* w = nsWindowOf(window);
    if (!w)
        return;
    const NSRect frame = NSMakeRect(g.x(), primaryScreenHeight() - g.y() - g.height(), g.width(), g.height());
    [w setFrame:frame display:YES];
    [w orderFrontRegardless];
}

void setClickThrough(QWindow* window, bool clickThrough)
{
    NSWindow* w = nsWindowOf(window);
    if (w)
        w.ignoresMouseEvents = clickThrough;
}

void takeFocus(QWindow* window)
{
    NSWindow* w = nsWindowOf(window);
    if (!w || w.isKeyWindow)
        return;
    NSRunningApplication* front = NSWorkspace.sharedWorkspace.frontmostApplication;
    if (front && front.processIdentifier != NSProcessInfo.processInfo.processIdentifier)
        g_previousApp = front;
    [w makeKeyAndOrderFront:nil];
}

void releaseFocus(QWindow* window)
{
    NSWindow* w = nsWindowOf(window);
    if (!w || !w.isKeyWindow)
        return;
    [w resignKeyWindow];
    if (g_previousApp && !g_previousApp.terminated)
        [g_previousApp activateWithOptions:0];
}

bool isMouseButtonDown()
{
    return NSEvent.pressedMouseButtons != 0;
}

qint64 dragPasteboardChangeCount()
{
    return static_cast<qint64>([NSPasteboard pasteboardWithName:NSPasteboardNameDrag].changeCount);
}

QImage fileIcon(const QString& path, int pixels)
{
    @autoreleasepool {
        NSImage* icon = [NSWorkspace.sharedWorkspace iconForFile:path.toNSString()];
        if (!icon)
            return {};
        NSBitmapImageRep* rep = [[NSBitmapImageRep alloc]
            initWithBitmapDataPlanes:nullptr
                          pixelsWide:pixels
                          pixelsHigh:pixels
                       bitsPerSample:8
                     samplesPerPixel:4
                            hasAlpha:YES
                            isPlanar:NO
                      colorSpaceName:NSCalibratedRGBColorSpace
                         bytesPerRow:0
                        bitsPerPixel:0];
        if (!rep)
            return {};
        rep.size = NSMakeSize(pixels, pixels);
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:rep]];
        [icon drawInRect:NSMakeRect(0, 0, pixels, pixels)
                fromRect:NSZeroRect
               operation:NSCompositingOperationCopy
                fraction:1.0];
        [NSGraphicsContext restoreGraphicsState];
        NSData* png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        return png ? QImage::fromData(QByteArray::fromNSData(png), "PNG") : QImage();
    }
}

void openFile(const QString& path)
{
    [NSWorkspace.sharedWorkspace openURL:[NSURL fileURLWithPath:path.toNSString()]];
}

void revealInFinder(const QString& path)
{
    [NSWorkspace.sharedWorkspace activateFileViewerSelectingURLs:@[ [NSURL fileURLWithPath:path.toNSString()] ]];
}

void playSound(const QString& name)
{
    [[NSSound soundNamed:name.toNSString()] play];
}

bool launchAtLoginEnabled()
{
    if (@available(macOS 13.0, *)) {
        const SMAppServiceStatus status = SMAppService.mainAppService.status;
        return status == SMAppServiceStatusEnabled || status == SMAppServiceStatusRequiresApproval;
    }
    return false;
}

bool setLaunchAtLogin(bool enable, QString* error)
{
    if (@available(macOS 13.0, *)) {
        SMAppService* service = SMAppService.mainAppService;
        NSError* err = nil;
        const BOOL ok = enable ? [service registerAndReturnError:&err] : [service unregisterAndReturnError:&err];
        if (!ok) {
            if (error)
                *error = QString::fromNSString(err.localizedDescription ?: @"unknown error");
            return false;
        }
        if (enable && service.status == SMAppServiceStatusRequiresApproval) {
            [SMAppService openSystemSettingsLoginItems];
            if (error)
                *error = QStringLiteral("Подтверди Isle в «Объектах входа»");
        }
        return true;
    }
    if (error)
        *error = QStringLiteral("Нужна macOS 13 или новее");
    return false;
}

} // namespace native
