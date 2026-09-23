#pragma once

#include "Media.h"

#include <QElapsedTimer>
#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

#include <memory>

class ImageStore;

// What's playing right now + transport controls, for QML.
class NowPlaying : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by NotchController")

    Q_PROPERTY(bool available READ available NOTIFY changed)
    Q_PROPERTY(bool playing READ playing NOTIFY changed)
    Q_PROPERTY(QString title READ title NOTIFY changed)
    Q_PROPERTY(QString artist READ artist NOTIFY changed)
    Q_PROPERTY(QString album READ album NOTIFY changed)
    Q_PROPERTY(QString appName READ appName NOTIFY changed)
    Q_PROPERTY(QString artworkSource READ artworkSource NOTIFY changed)
    Q_PROPERTY(double duration READ duration NOTIFY changed)
    Q_PROPERTY(double position READ position NOTIFY positionChanged)

public:
    NowPlaying(std::shared_ptr<ImageStore> images, QObject* parent = nullptr);

    void start();

    bool available() const { return m_available; }
    bool playing() const { return m_playing; }
    QString title() const { return m_title; }
    QString artist() const { return m_artist; }
    QString album() const { return m_album; }
    QString appName() const { return m_appName; }
    QString artworkSource() const { return m_artworkSource; }
    double duration() const { return m_duration; }
    double position() const { return m_position; }

    Q_INVOKABLE void togglePlay();
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE QString formatTime(double seconds) const;

signals:
    void changed();
    void positionChanged();

private:
    enum class Source { None, System, Scripted };

    void poll();
    void pollScripted();
    void apply(const media::Track& track, Source source);
    void clear();
    void send(media::Command command);
    void advance();

    std::shared_ptr<ImageStore> m_images;
    QTimer m_pollTimer;
    QTimer m_positionTimer;
    bool m_systemBusy = false;
    int m_systemMisses = 0;
    quint64 m_pollCount = 0;
    QElapsedTimer m_busyClock;

    Source m_source = Source::None;
    QString m_trackKey;
    QString m_appId;
    int m_artGeneration = 0;

    bool m_available = false;
    bool m_playing = false;
    QString m_title, m_artist, m_album, m_appName, m_artworkSource;
    double m_duration = 0;
    double m_position = 0;
};
