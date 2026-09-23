// Compiled as Objective-C++ with ARC.

#include "Media.h"

#include <QStringList>

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#include <dlfcn.h>
#include <memory>

namespace {

// ------------------------------------------------------------ MediaRemote

using GetNowPlayingInfoFn = void (*)(dispatch_queue_t, void (^)(CFDictionaryRef));
using SendCommandFn = Boolean (*)(int, CFDictionaryRef);

struct MediaRemote {
    GetNowPlayingInfoFn getInfo = nullptr;
    SendCommandFn sendCommand = nullptr;
};

const MediaRemote& mediaRemote()
{
    static const MediaRemote api = [] {
        MediaRemote m;
        void* handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
        if (handle) {
            m.getInfo = reinterpret_cast<GetNowPlayingInfoFn>(dlsym(handle, "MRMediaRemoteGetNowPlayingInfo"));
            m.sendCommand = reinterpret_cast<SendCommandFn>(dlsym(handle, "MRMediaRemoteSendCommand"));
        }
        return m;
    }();
    return api;
}

// MRMediaRemoteCommand values
constexpr int kMRTogglePlayPause = 2;
constexpr int kMRNextTrack = 4;
constexpr int kMRPreviousTrack = 5;

QString stringValue(id value)
{
    return [value isKindOfClass:[NSString class]] ? QString::fromNSString((NSString*)value) : QString();
}

double numberValue(id value)
{
    return [value isKindOfClass:[NSNumber class]] ? [(NSNumber*)value doubleValue] : 0.0;
}

// ------------------------------------------------------------ AppleScript

struct Player {
    NSString* bundleId;
    NSString* appName;      // name AppleScript uses
    const char* displayName;
    bool spotify;
};

const Player kPlayers[] = {
    { @"com.spotify.client", @"Spotify", "Spotify", true },
    { @"com.apple.Music", @"Music", "Музыка", false },
};

bool isRunning(NSString* bundleId)
{
    // Never talk to a player that isn't running: `tell application` would launch it.
    return [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleId].count > 0;
}

NSAppleEventDescriptor* runScript(NSString* source)
{
    // Compiling is the slow part; keep compiled scripts.
    static NSMutableDictionary<NSString*, NSAppleScript*>* cache = [NSMutableDictionary dictionary];
    NSAppleScript* script = cache[source];
    if (!script) {
        script = [[NSAppleScript alloc] initWithSource:source];
        if (!script)
            return nil;
        cache[source] = script;
    }
    NSDictionary* error = nil;
    NSAppleEventDescriptor* result = [script executeAndReturnError:&error];
    return error ? nil : result;
}

double parseNumber(const QString& text)
{
    QString t = text.trimmed();
    t.replace(QLatin1Char(','), QLatin1Char('.'));   // AppleScript uses the system locale
    return t.toDouble();
}

media::Track queryPlayer(const Player& p)
{
    NSString* source = p.spotify
        ? @"tell application \"Spotify\"\n"
           "  try\n"
           "    if player state is stopped then return \"\"\n"
           "    set t to current track\n"
           "    return (player state as text) & linefeed & (name of t) & linefeed & (artist of t) & linefeed "
           "& (album of t) & linefeed & ((duration of t) / 1000) & linefeed & (player position) & linefeed & (artwork url of t)\n"
           "  on error\n"
           "    return \"\"\n"
           "  end try\n"
           "end tell"
        : @"tell application \"Music\"\n"
           "  try\n"
           "    if player state is stopped then return \"\"\n"
           "    set t to current track\n"
           "    return (player state as text) & linefeed & (name of t) & linefeed & (artist of t) & linefeed "
           "& (album of t) & linefeed & (duration of t) & linefeed & (player position)\n"
           "  on error\n"
           "    return \"\"\n"
           "  end try\n"
           "end tell";

    media::Track track;
    NSAppleEventDescriptor* result = runScript(source);
    const QString text = result.stringValue ? QString::fromNSString(result.stringValue) : QString();
    const QStringList parts = text.split(QLatin1Char('\n'));
    if (parts.size() < 6 || parts.at(1).isEmpty())
        return track;

    track.valid = true;
    track.playing = parts.at(0).trimmed() == QLatin1String("playing");
    track.title = parts.at(1);
    track.artist = parts.at(2);
    track.album = parts.at(3);
    track.duration = parseNumber(parts.at(4));
    track.position = parseNumber(parts.at(5));
    if (parts.size() > 6)
        track.artworkUrl = parts.at(6).trimmed();
    track.appId = QString::fromNSString(p.bundleId);
    track.appName = QString::fromUtf8(p.displayName);
    return track;
}

QImage musicArtwork()
{
    for (NSString* property in @[ @"raw data", @"data" ]) {
        NSString* source = [NSString stringWithFormat:
            @"tell application \"Music\"\n"
             "  try\n"
             "    return %@ of artwork 1 of current track\n"
             "  end try\n"
             "end tell", property];
        NSAppleEventDescriptor* result = runScript(source);
        NSData* data = result.data;
        if (data.length > 0) {
            const QImage image = QImage::fromData(QByteArray::fromNSData(data));
            if (!image.isNull())
                return image;
        }
    }
    return {};
}

} // namespace

namespace media {

bool systemAvailable()
{
    return mediaRemote().getInfo != nullptr;
}

void querySystem(std::function<void(const Track&)> callback)
{
    const MediaRemote& mr = mediaRemote();
    if (!mr.getInfo) {
        callback(Track {});
        return;
    }
    auto shared = std::make_shared<std::function<void(const Track&)>>(std::move(callback));
    mr.getInfo(dispatch_get_main_queue(), ^(CFDictionaryRef info) {
        Track track;
        if (info) {
            NSDictionary* d = (__bridge NSDictionary*)info;
            track.title = stringValue(d[@"kMRMediaRemoteNowPlayingInfoTitle"]);
            track.artist = stringValue(d[@"kMRMediaRemoteNowPlayingInfoArtist"]);
            track.album = stringValue(d[@"kMRMediaRemoteNowPlayingInfoAlbum"]);
            track.duration = numberValue(d[@"kMRMediaRemoteNowPlayingInfoDuration"]);
            track.playing = numberValue(d[@"kMRMediaRemoteNowPlayingInfoPlaybackRate"]) > 0;
            track.position = numberValue(d[@"kMRMediaRemoteNowPlayingInfoElapsedTime"]);
            id timestamp = d[@"kMRMediaRemoteNowPlayingInfoTimestamp"];
            if (track.playing && [timestamp isKindOfClass:[NSDate class]])
                track.position += -[(NSDate*)timestamp timeIntervalSinceNow];
            id artwork = d[@"kMRMediaRemoteNowPlayingInfoArtworkData"];
            if ([artwork isKindOfClass:[NSData class]] && [(NSData*)artwork length] > 0)
                track.artwork = QImage::fromData(QByteArray::fromNSData((NSData*)artwork));
            track.valid = !track.title.isEmpty();
        }
        (*shared)(track);
    });
}

bool sendSystem(Command command)
{
    const MediaRemote& mr = mediaRemote();
    if (!mr.sendCommand)
        return false;
    const int code = command == Command::Next ? kMRNextTrack
                   : command == Command::Previous ? kMRPreviousTrack
                   : kMRTogglePlayPause;
    return mr.sendCommand(code, nullptr);
}

Track queryScripted(const QString& knownKey)
{
    Track paused;
    for (const Player& p : kPlayers) {
        if (!isRunning(p.bundleId))
            continue;
        Track t = queryPlayer(p);
        if (!t.valid)
            continue;
        if (t.playing) {
            paused = t;
            break;
        }
        if (!paused.valid)
            paused = t;
    }
    if (paused.valid && paused.appId == QLatin1String("com.apple.Music")
        && paused.title + QChar(0x1f) + paused.artist != knownKey)
        paused.artwork = musicArtwork();
    return paused;
}

void sendScripted(const QString& appId, Command command)
{
    for (const Player& p : kPlayers) {
        if (appId != QString::fromNSString(p.bundleId) || !isRunning(p.bundleId))
            continue;
        NSString* verb = command == Command::Next ? @"next track"
                       : command == Command::Previous ? @"previous track"
                       : @"playpause";
        runScript([NSString stringWithFormat:@"tell application \"%@\" to %@", p.appName, verb]);
    }
}

} // namespace media
