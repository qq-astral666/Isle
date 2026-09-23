#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QString>
#include <QTimer>

// Countdown timer (pomodoro-style). Time is measured with a monotonic clock,
// so it stays exact even if ticks are delayed (e.g. while the Mac sleeps the
// remaining time keeps running out, like a kitchen timer).
class FocusTimer : public QObject {
    Q_OBJECT

    Q_PROPERTY(int duration READ duration NOTIFY stateChanged)
    Q_PROPERTY(int remaining READ remaining NOTIFY remainingChanged)
    Q_PROPERTY(double progress READ progress NOTIFY remainingChanged)
    Q_PROPERTY(QString remainingText READ remainingText NOTIFY remainingChanged)
    Q_PROPERTY(bool running READ running NOTIFY stateChanged)
    Q_PROPERTY(bool active READ active NOTIFY stateChanged)
    Q_PROPERTY(int lastMinutes READ lastMinutes NOTIFY stateChanged)

public:
    explicit FocusTimer(QObject* parent = nullptr);

    int duration() const { return int(m_durationMs / 1000); }     // seconds
    int remaining() const;                                          // seconds, rounded up
    qint64 remainingMs() const;
    double progress() const;                                        // 0..1 elapsed share
    QString remainingText() const;
    bool running() const { return m_running; }
    bool active() const { return m_durationMs > 0; }                // running or paused
    int lastMinutes() const { return m_lastSeconds / 60; }

    Q_INVOKABLE void start(int seconds);
    Q_INVOKABLE void startMinutes(int minutes) { start(minutes * 60); }
    Q_INVOKABLE void pause();
    Q_INVOKABLE void resume();
    Q_INVOKABLE void toggle();
    Q_INVOKABLE void reset();
    Q_INVOKABLE void addMinutes(int minutes);

    static QString format(qint64 seconds);

signals:
    void stateChanged();
    void remainingChanged();
    void finished();

private:
    void onTick();

    QTimer m_tick;
    QElapsedTimer m_clock;          // runs since the last start/resume
    qint64 m_durationMs = 0;        // 0 = idle
    qint64 m_remainingAtResumeMs = 0;
    bool m_running = false;
    int m_lastSeconds = 25 * 60;
};
