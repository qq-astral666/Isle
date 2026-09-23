#pragma once

#include "FocusTimer.h"
#include "NowPlaying.h"
#include "ShelfModel.h"

#include <QElapsedTimer>
#include <QObject>
#include <QPointer>
#include <QQuickWindow>
#include <QRect>
#include <QSize>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

#include <memory>

class ImageStore;

// Owns the notch window's behaviour:
//  * geometry — where the notch is and how big;
//  * hover state machine — expand on hover, collapse on leave, expand while a
//    file is being dragged towards the notch;
//  * click-through — the window is transparent to the mouse unless expanded,
//    so the menu bar underneath keeps working;
//  * the three modules (music, timer, shelf) and settings.
class NotchController : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Created in main.cpp")

    Q_PROPERTY(bool expanded READ expanded NOTIFY expandedChanged)
    Q_PROPERTY(bool dragHover READ dragHover NOTIFY dragHoverChanged)
    Q_PROPERTY(bool hasNotch READ hasNotch NOTIFY geometryChanged)
    Q_PROPERTY(int notchWidth READ notchWidth NOTIFY geometryChanged)
    Q_PROPERTY(int notchHeight READ notchHeight NOTIFY geometryChanged)
    Q_PROPERTY(int windowWidth READ windowWidth CONSTANT)
    Q_PROPERTY(int windowHeight READ windowHeight CONSTANT)
    Q_PROPERTY(QSize collapsedSize READ collapsedSize WRITE setCollapsedSize NOTIFY hitAreaChanged)
    Q_PROPERTY(QSize expandedSize READ expandedSize WRITE setExpandedSize NOTIFY hitAreaChanged)
    Q_PROPERTY(bool timerFlash READ timerFlash NOTIFY timerFlashChanged)
    Q_PROPERTY(bool settingsOpen READ settingsOpen WRITE setSettingsOpen NOTIFY settingsOpenChanged)

    Q_PROPERTY(FocusTimer* timer READ timer CONSTANT)
    Q_PROPERTY(ShelfModel* shelf READ shelf CONSTANT)
    Q_PROPERTY(NowPlaying* media READ media CONSTANT)

    Q_PROPERTY(bool showMediaCollapsed READ showMediaCollapsed WRITE setShowMediaCollapsed NOTIFY settingsChanged)
    Q_PROPERTY(bool timerSound READ timerSound WRITE setTimerSound NOTIFY settingsChanged)
    Q_PROPERTY(bool launchAtLogin READ launchAtLogin WRITE setLaunchAtLogin NOTIFY launchAtLoginChanged)

public:
    static constexpr int kWindowWidth = 760;
    static constexpr int kWindowHeight = 260;

    NotchController(std::shared_ptr<ImageStore> images, QObject* parent = nullptr);
    ~NotchController() override;

    void attach(QQuickWindow* window);

    bool expanded() const { return m_expanded; }
    bool dragHover() const { return m_dragHover; }
    bool hasNotch() const { return m_hasNotch; }
    int notchWidth() const { return m_notchWidth; }
    int notchHeight() const { return m_notchHeight; }
    int windowWidth() const { return kWindowWidth; }
    int windowHeight() const { return kWindowHeight; }
    QSize collapsedSize() const { return m_collapsedSize; }
    void setCollapsedSize(const QSize& size);
    QSize expandedSize() const { return m_expandedSize; }
    void setExpandedSize(const QSize& size);
    bool timerFlash() const { return m_timerFlash; }
    bool settingsOpen() const { return m_settingsOpen; }
    void setSettingsOpen(bool open);

    FocusTimer* timer() const { return m_timer; }
    ShelfModel* shelf() const { return m_shelf; }
    NowPlaying* media() const { return m_media; }

    bool showMediaCollapsed() const { return m_showMediaCollapsed; }
    void setShowMediaCollapsed(bool value);
    bool timerSound() const { return m_timerSound; }
    void setTimerSound(bool value);
    bool launchAtLogin() const;
    void setLaunchAtLogin(bool enable);

    Q_INVOKABLE void collapse();
    Q_INVOKABLE void addFiles(const QList<QUrl>& urls);
    Q_INVOKABLE void openFile(const QString& path);
    Q_INVOKABLE void revealFile(const QString& path);
    Q_INVOKABLE void quit();

signals:
    void expandedChanged();
    void dragHoverChanged();
    void geometryChanged();
    void hitAreaChanged();
    void timerFlashChanged();
    void settingsOpenChanged();
    void settingsChanged();
    void launchAtLoginChanged();
    void toast(const QString& message);

private:
    void updateGeometry();
    void poll();
    void setExpanded(bool expanded);
    void setDragHover(bool hover);
    void setInteractive(bool interactive);
    void onTimerFinished();
    void refreshShelfIcons();
    QRect shapeRect(const QSize& size, int marginX, int marginBottom) const;

    std::shared_ptr<ImageStore> m_images;
    FocusTimer* m_timer;
    ShelfModel* m_shelf;
    NowPlaying* m_media;

    QPointer<QQuickWindow> m_window;
    QTimer m_pollTimer;
    QElapsedTimer m_hoverClock;
    QElapsedTimer m_leaveClock;
    QElapsedTimer m_pinClock;
    int m_pinMs = 0;

    QRect m_screen;
    QRect m_windowRect;
    bool m_hasNotch = false;
    int m_notchWidth = 190;
    int m_notchHeight = 32;
    QSize m_collapsedSize { 190, 32 };
    QSize m_expandedSize { 640, 190 };

    bool m_expanded = false;
    bool m_interactive = false;
    bool m_dragHover = false;
    bool m_wasMouseDown = false;
    bool m_pressStartedInside = false;
    qint64 m_dragCountAtPress = 0;

    bool m_timerFlash = false;
    bool m_settingsOpen = false;
    bool m_showMediaCollapsed = true;
    bool m_timerSound = true;
};
