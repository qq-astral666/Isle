#pragma once

#include <QImage>
#include <QString>

#include <functional>

// "Now playing" sources. Media_mac.mm / Platform_stub.cpp.
//
//  1. MediaRemote (private framework): sees every player — browsers,
//     YouTube, Яндекс Музыка... Apple restricted reading it to entitled apps
//     in macOS 15.4, so on new systems it usually returns nothing.
//  2. AppleScript to Spotify and Apple Music: always works, needs a one-time
//     "Isle wants to control…" permission.
namespace media {

struct Track {
    bool valid = false;
    bool playing = false;
    QString title;
    QString artist;
    QString album;
    QString appId;         // bundle id of the player (scripted source)
    QString appName;
    double duration = 0;   // seconds
    double position = 0;   // seconds
    QString artworkUrl;    // Spotify gives a URL…
    QImage artwork;        // …MediaRemote and Music give bytes
};

enum class Command { TogglePlay, Next, Previous };

bool systemAvailable();
// Async, callback runs on the main thread. Track.valid == false if unknown.
void querySystem(std::function<void(const Track&)> callback);
bool sendSystem(Command command);

// Synchronous. Artwork is fetched only if the track differs from `knownKey`
// (title + '\x1f' + artist), because it's the expensive part.
Track queryScripted(const QString& knownKey);
void sendScripted(const QString& appId, Command command);

} // namespace media
