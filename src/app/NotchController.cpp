#include "NotchController.h"

#include "ImageStore.h"
#include "Native.h"

#include <QCoreApplication>
#include <QCursor>
#include <QGuiApplication>
#include <QScreen>
#include <QSettings>

namespace {

constexpr int kPollMs = 40;
constexpr int kHoverDelayMs = 140;   // don't pop open when the cursor merely passes by
constexpr int kLeaveDelayMs = 320;
constexpr int kFlashMs = 5000;

namespace keys {
const QString showMedia = QStringLiteral("showMediaCollapsed");
const QString timerSound = QStringLiteral("timerSound");
const QString shelf = QStringLiteral("shelf/paths");
} // namespace keys

} // namespace

NotchController::NotchController(std::shared_ptr<ImageStore> images, QObject* parent)
    : QObject(parent)
    , m_images(images)
    , m_timer(new FocusTimer(this))
    , m_shelf(new ShelfModel(keys::shelf, this))
    , m_media(new NowPlaying(images, this))
{
    QSettings s;
    m_showMediaCollapsed = s.value(keys::showMedia, true).toBool();
    m_timerSound = s.value(keys::timerSound, true).toBool();

    m_pollTimer.setInterval(kPollMs);
    connect(&m_pollTimer, &QTimer::timeout, this, &NotchController::poll);
    connect(m_timer, &FocusTimer::finished, this, &NotchController::onTimerFinished);
    connect(m_shelf, &ShelfModel::countChanged, this, &NotchController::refreshShelfIcons);
    refreshShelfIcons();
}

NotchController::~NotchController() = default;

void NotchController::attach(QQuickWindow* window)
{
    m_window = window;
    updateGeometry();

    window->create();
    native::configureWindow(window);
    window->show();
    native::configureWindow(window);          // NSWindow definitely exists now
    native::placeWindow(window, m_windowRect);
    native::setClickThrough(window, true);

    auto regeometry = [this] { QTimer::singleShot(300, this, &NotchController::updateGeometry); };
    connect(qApp, &QGuiApplication::screenAdded, this, regeometry);
    connect(qApp, &QGuiApplication::screenRemoved, this, regeometry);
    connect(qApp, &QGuiApplication::primaryScreenChanged, this, regeometry);
    for (QScreen* screen : QGuiApplication::screens())
        connect(screen, &QScreen::geometryChanged, this, regeometry);

    m_media->start();
    m_pollTimer.start();
}

void NotchController::updateGeometry()
{
    const native::NotchInfo info = native::notchInfo();
    m_screen = info.screen;
    if (!m_screen.isValid()) {
        if (const QScreen* s = QGuiApplication::primaryScreen())
            m_screen = s->geometry();
    }
    m_hasNotch = info.hasNotch;
    m_notchWidth = info.notchWidth;
    m_notchHeight = info.notchHeight;
    m_windowRect = QRect(m_screen.x() + (m_screen.width() - kWindowWidth) / 2, m_screen.y(),
                         kWindowWidth, kWindowHeight);
    if (m_window) {
        m_window->setGeometry(m_windowRect);
        native::placeWindow(m_window, m_windowRect);
    }
    emit geometryChanged();
}

QRect NotchController::shapeRect(const QSize& size, int marginX, int marginBottom) const
{
    const int cx = m_screen.x() + m_screen.width() / 2;
    return QRect(cx - size.width() / 2 - marginX, m_screen.y(),
                 size.width() + 2 * marginX, size.height() + marginBottom);
}

// ------------------------------------------------------------------ hover --

void NotchController::poll()
{
    const QPoint cursor = QCursor::pos();
    const bool down = native::isMouseButtonDown();

    // A drag-and-drop session bumps the drag pasteboard. Comparing it with
    // its value at mouse-down tells a file drag from a click on the menu bar.
    if (down && !m_wasMouseDown) {
        m_dragCountAtPress = native::dragPasteboardChangeCount();
        m_pressStartedInside = m_expanded && shapeRect(m_expandedSize, 14, 16).contains(cursor);
    }
    const bool dragging = down && !m_pressStartedInside
        && native::dragPasteboardChangeCount() != m_dragCountAtPress;
    m_wasMouseDown = down;

    if (!m_expanded) {
        const QRect hot = shapeRect(m_collapsedSize, 8, 6);
        const QRect dragZone = shapeRect(m_collapsedSize, 140, 80);
        if (dragging && dragZone.contains(cursor)) {
            setExpanded(true);
        } else if (!down && hot.contains(cursor)) {
            if (!m_hoverClock.isValid())
                m_hoverClock.start();
            else if (m_hoverClock.elapsed() >= kHoverDelayMs)
                setExpanded(true);
        } else {
            m_hoverClock.invalidate();
        }
    }

    if (m_expanded) {
        const QRect area = shapeRect(m_expandedSize, 14, 16);
        const bool inside = area.contains(cursor);
        const bool pinned = m_pinClock.isValid() && m_pinClock.elapsed() < m_pinMs;
        // Keep open while the button is held after pressing inside
        // (dragging a file out of the shelf).
        const bool holding = down && m_pressStartedInside;

        if (inside || holding || pinned || (dragging && shapeRect(m_expandedSize, 60, 60).contains(cursor)))
            m_leaveClock.invalidate();
        else if (!m_leaveClock.isValid())
            m_leaveClock.start();
        else if (m_leaveClock.elapsed() >= kLeaveDelayMs)
            setExpanded(false);

        setInteractive(m_expanded && (inside || holding));
        setDragHover(m_expanded && dragging && inside);
    } else {
        setInteractive(false);
        setDragHover(false);
    }
}

void NotchController::setExpanded(bool expanded)
{
    if (expanded == m_expanded)
        return;
    m_expanded = expanded;
    m_hoverClock.invalidate();
    m_leaveClock.invalidate();
    if (!expanded) {
        m_pinClock.invalidate();
        setSettingsOpen(false);
    }
    emit expandedChanged();
}

void NotchController::setInteractive(bool interactive)
{
    if (interactive == m_interactive || !m_window)
        return;
    m_interactive = interactive;
    native::setClickThrough(m_window, !interactive);
    if (interactive)
        native::takeFocus(m_window);
    else
        native::releaseFocus(m_window);
}

void NotchController::setDragHover(bool hover)
{
    if (hover == m_dragHover)
        return;
    m_dragHover = hover;
    emit dragHoverChanged();
}

void NotchController::collapse()
{
    setExpanded(false);
}

void NotchController::setCollapsedSize(const QSize& size)
{
    if (size == m_collapsedSize)
        return;
    m_collapsedSize = size;
    emit hitAreaChanged();
}

void NotchController::setExpandedSize(const QSize& size)
{
    if (size == m_expandedSize)
        return;
    m_expandedSize = size;
    emit hitAreaChanged();
}

// ----------------------------------------------------------------- timer --

void NotchController::onTimerFinished()
{
    if (m_timerSound)
        native::playSound(QStringLiteral("Glass"));
    m_timerFlash = true;
    emit timerFlashChanged();

    m_pinMs = kFlashMs;
    m_pinClock.start();
    setExpanded(true);

    QTimer::singleShot(kFlashMs, this, [this] {
        m_timerFlash = false;
        emit timerFlashChanged();
    });
}

// ----------------------------------------------------------------- shelf --

void NotchController::addFiles(const QList<QUrl>& urls)
{
    const int added = m_shelf->addUrls(urls);
    if (added > 0)
        emit toast(added == 1 ? QStringLiteral("Файл на полке")
                              : QStringLiteral("На полке +%1").arg(added));
}

void NotchController::refreshShelfIcons()
{
    for (const QString& path : m_shelf->paths()) {
        const QString key = ShelfModel::iconKey(path);
        if (!m_images->contains(key))
            m_images->put(key, native::fileIcon(path, 96));
    }
}

void NotchController::openFile(const QString& path)
{
    native::openFile(path);
    collapse();
}

void NotchController::revealFile(const QString& path)
{
    native::revealInFinder(path);
    collapse();
}

// -------------------------------------------------------------- settings --

void NotchController::setSettingsOpen(bool open)
{
    if (open == m_settingsOpen)
        return;
    m_settingsOpen = open;
    emit settingsOpenChanged();
}

void NotchController::setShowMediaCollapsed(bool value)
{
    if (value == m_showMediaCollapsed)
        return;
    m_showMediaCollapsed = value;
    QSettings().setValue(keys::showMedia, value);
    emit settingsChanged();
}

void NotchController::setTimerSound(bool value)
{
    if (value == m_timerSound)
        return;
    m_timerSound = value;
    QSettings().setValue(keys::timerSound, value);
    emit settingsChanged();
}

bool NotchController::launchAtLogin() const
{
    return native::launchAtLoginEnabled();
}

void NotchController::setLaunchAtLogin(bool enable)
{
    QString error;
    const bool ok = native::setLaunchAtLogin(enable, &error);
    if (!error.isEmpty())
        emit toast(error);
    else if (ok)
        emit toast(enable ? QStringLiteral("Isle будет запускаться при входе")
                          : QStringLiteral("Автозапуск выключен"));
    emit launchAtLoginChanged();
}

void NotchController::quit()
{
    QCoreApplication::quit();
}
