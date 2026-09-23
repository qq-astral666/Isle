#include "NowPlaying.h"

#include "ImageStore.h"

#include <QPointer>

#include <algorithm>

namespace {
constexpr int kPollMs = 1000;
// After this many empty MediaRemote answers in a row we stop asking it
// (macOS 15.4+ hides now-playing info from non-Apple apps).
constexpr int kMaxSystemMisses = 5;
}

NowPlaying::NowPlaying(std::shared_ptr<ImageStore> images, QObject* parent)
    : QObject(parent)
    , m_images(std::move(images))
{
    m_pollTimer.setInterval(kPollMs);
    connect(&m_pollTimer, &QTimer::timeout, this, &NowPlaying::poll);

    m_positionTimer.setInterval(250);
    connect(&m_positionTimer, &QTimer::timeout, this, &NowPlaying::advance);
}

void NowPlaying::start()
{
    poll();
    m_pollTimer.start();
    m_positionTimer.start();
}

QString NowPlaying::formatTime(double seconds) const
{
    const int s = std::max(0, int(seconds));
    return QStringLiteral("%1:%2").arg(s / 60).arg(s % 60, 2, 10, QLatin1Char('0'));
}

void NowPlaying::poll()
{
    ++m_pollCount;
    if (m_systemBusy) {
        // MediaRemote normally answers within milliseconds; never wait forever.
        if (m_busyClock.elapsed() < 3000)
            return;
        m_systemBusy = false;
        ++m_systemMisses;
    }
    // Retry MediaRemote now and then: it also answers "nothing" when nothing
    // plays, so a few misses don't prove it is blocked.
    const bool trySystem = media::systemAvailable()
        && (m_systemMisses < kMaxSystemMisses || m_pollCount % 30 == 0);
    if (!trySystem) {
        pollScripted();
        return;
    }

    m_systemBusy = true;
    m_busyClock.start();
    QPointer<NowPlaying> self(this);
    media::querySystem([self](const media::Track& track) {
        if (!self)
            return;
        self->m_systemBusy = false;
        if (track.valid) {
            self->m_systemMisses = 0;
            self->apply(track, Source::System);
        } else {
            ++self->m_systemMisses;
            self->pollScripted();
        }
    });
}

void NowPlaying::pollScripted()
{
    const media::Track track = media::queryScripted(m_trackKey);
    if (track.valid)
        apply(track, Source::Scripted);
    else
        clear();
}

void NowPlaying::apply(const media::Track& t, Source source)
{
    const QString key = t.title + QChar(0x1f) + t.artist;
    const bool trackChanged = key != m_trackKey;

    m_trackKey = key;
    m_source = source;
    m_appId = t.appId;
    m_available = true;
    m_playing = t.playing;
    m_title = t.title;
    m_artist = t.artist;
    m_album = t.album;
    m_appName = t.appName;
    m_duration = t.duration;
    m_position = std::clamp(t.position, 0.0, t.duration > 0 ? t.duration : t.position);

    if (!t.artwork.isNull() && (trackChanged || !m_artworkSource.startsWith(QLatin1String("image://")))) {
        m_images->remove(QStringLiteral("art%1").arg(m_artGeneration - 1));
        ++m_artGeneration;
        const QString id = QStringLiteral("art%1").arg(m_artGeneration);
        m_images->put(id, t.artwork);
        m_artworkSource = QStringLiteral("image://img/") + id;
    } else if (!t.artworkUrl.isEmpty()) {
        m_artworkSource = t.artworkUrl;
    } else if (trackChanged) {
        m_artworkSource.clear();
    }

    emit changed();
    emit positionChanged();
}

void NowPlaying::clear()
{
    if (!m_available)
        return;
    m_available = false;
    m_playing = false;
    m_trackKey.clear();
    m_title.clear();
    m_artist.clear();
    m_album.clear();
    m_appName.clear();
    m_artworkSource.clear();
    m_duration = 0;
    m_position = 0;
    m_source = Source::None;
    emit changed();
    emit positionChanged();
}

void NowPlaying::advance()
{
    // Smooth progress between polls.
    if (!m_playing || m_duration <= 0)
        return;
    m_position = std::min(m_duration, m_position + m_positionTimer.interval() / 1000.0);
    emit positionChanged();
}

void NowPlaying::send(media::Command command)
{
    if (m_source == Source::System)
        media::sendSystem(command);
    else if (!m_appId.isEmpty())
        media::sendScripted(m_appId, command);
    else
        media::sendSystem(command);

    if (command == media::Command::TogglePlay) {
        m_playing = !m_playing;   // optimistic; the next poll confirms
        emit changed();
    }
    QTimer::singleShot(350, this, &NowPlaying::poll);
}

void NowPlaying::togglePlay() { send(media::Command::TogglePlay); }
void NowPlaying::next() { send(media::Command::Next); }
void NowPlaying::previous() { send(media::Command::Previous); }
