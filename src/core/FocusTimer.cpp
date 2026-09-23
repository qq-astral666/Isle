#include "FocusTimer.h"

#include <algorithm>

FocusTimer::FocusTimer(QObject* parent)
    : QObject(parent)
{
    m_tick.setInterval(250);
    connect(&m_tick, &QTimer::timeout, this, &FocusTimer::onTick);
}

qint64 FocusTimer::remainingMs() const
{
    if (!m_running)
        return m_remainingAtResumeMs;
    return std::max<qint64>(0, m_remainingAtResumeMs - m_clock.elapsed());
}

int FocusTimer::remaining() const
{
    return int((remainingMs() + 999) / 1000);
}

double FocusTimer::progress() const
{
    if (m_durationMs <= 0)
        return 0.0;
    return std::clamp(1.0 - double(remainingMs()) / double(m_durationMs), 0.0, 1.0);
}

QString FocusTimer::format(qint64 seconds)
{
    seconds = std::max<qint64>(0, seconds);
    const qint64 h = seconds / 3600;
    const qint64 m = (seconds % 3600) / 60;
    const qint64 s = seconds % 60;
    if (h > 0)
        return QStringLiteral("%1:%2:%3").arg(h).arg(m, 2, 10, QLatin1Char('0')).arg(s, 2, 10, QLatin1Char('0'));
    return QStringLiteral("%1:%2").arg(m).arg(s, 2, 10, QLatin1Char('0'));
}

QString FocusTimer::remainingText() const
{
    return format(remaining());
}

void FocusTimer::start(int seconds)
{
    if (seconds <= 0)
        return;
    m_lastSeconds = seconds;
    m_durationMs = qint64(seconds) * 1000;
    m_remainingAtResumeMs = m_durationMs;
    m_running = true;
    m_clock.start();
    m_tick.start();
    emit stateChanged();
    emit remainingChanged();
}

void FocusTimer::pause()
{
    if (!m_running)
        return;
    m_remainingAtResumeMs = remainingMs();
    m_running = false;
    m_tick.stop();
    emit stateChanged();
    emit remainingChanged();
}

void FocusTimer::resume()
{
    if (m_running || m_durationMs <= 0 || m_remainingAtResumeMs <= 0)
        return;
    m_running = true;
    m_clock.start();
    m_tick.start();
    emit stateChanged();
}

void FocusTimer::toggle()
{
    if (m_running)
        pause();
    else if (active())
        resume();
    else
        start(m_lastSeconds);
}

void FocusTimer::reset()
{
    m_running = false;
    m_durationMs = 0;
    m_remainingAtResumeMs = 0;
    m_tick.stop();
    emit stateChanged();
    emit remainingChanged();
}

void FocusTimer::addMinutes(int minutes)
{
    if (!active() || minutes == 0)
        return;
    const qint64 delta = qint64(minutes) * 60000;
    m_remainingAtResumeMs = std::max<qint64>(1000, remainingMs() + delta);
    m_durationMs = std::max(m_durationMs + delta, m_remainingAtResumeMs);
    if (m_running)
        m_clock.start();
    emit stateChanged();
    emit remainingChanged();
}

void FocusTimer::onTick()
{
    emit remainingChanged();
    if (m_running && remainingMs() == 0) {
        m_running = false;
        m_durationMs = 0;
        m_remainingAtResumeMs = 0;
        m_tick.stop();
        emit stateChanged();
        emit remainingChanged();
        emit finished();
    }
}
