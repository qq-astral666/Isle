#include "ShelfModel.h"

#include <QCryptographicHash>
#include <QFileInfo>
#include <QSettings>

#include <utility>

ShelfModel::ShelfModel(QString settingsKey, QObject* parent)
    : QAbstractListModel(parent)
    , m_settingsKey(std::move(settingsKey))
{
    load();
}

int ShelfModel::rowCount(const QModelIndex& parent) const
{
    return parent.isValid() ? 0 : count();
}

QVariant ShelfModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= count())
        return {};
    const QString& path = m_paths.at(index.row());
    const QFileInfo info(path);

    switch (role) {
    case PathRole: return path;
    case NameRole: return info.fileName().isEmpty() ? path : info.fileName();
    case UrlRole: return QUrl::fromLocalFile(path).toString();
    case IsDirRole: return info.isDir();
    case SizeTextRole: return info.isDir() ? QStringLiteral("Папка") : sizeText(info.size());
    case IconKeyRole: return iconKey(path);
    default: return {};
    }
}

QHash<int, QByteArray> ShelfModel::roleNames() const
{
    return {
        { PathRole, "path" },
        { NameRole, "name" },
        { UrlRole, "fileUrl" },
        { IsDirRole, "isDir" },
        { SizeTextRole, "sizeText" },
        { IconKeyRole, "iconKey" },
    };
}

int ShelfModel::addUrls(const QList<QUrl>& urls)
{
    QStringList paths;
    for (const QUrl& url : urls) {
        if (url.isLocalFile())
            paths << url.toLocalFile();
    }
    return addPaths(paths);
}

int ShelfModel::addPaths(const QStringList& incoming)
{
    QStringList fresh;
    for (QString path : incoming) {
        while (path.size() > 1 && path.endsWith(QLatin1Char('/')))
            path.chop(1);
        if (path.isEmpty() || !QFileInfo::exists(path) || fresh.contains(path))
            continue;
        fresh << path;
    }
    if (fresh.isEmpty())
        return 0;

    int added = 0;
    QStringList next = fresh;
    for (const QString& p : fresh) {
        if (!m_paths.contains(p))
            ++added;
    }
    for (const QString& p : std::as_const(m_paths)) {
        if (!next.contains(p))
            next << p;
    }
    while (next.size() > kMaxItems)
        next.removeLast();

    beginResetModel();
    m_paths = next;
    endResetModel();
    save();
    emit countChanged();
    return added;
}

void ShelfModel::remove(int row)
{
    if (row < 0 || row >= count())
        return;
    beginRemoveRows({}, row, row);
    m_paths.removeAt(row);
    endRemoveRows();
    save();
    emit countChanged();
}

void ShelfModel::clear()
{
    if (m_paths.isEmpty())
        return;
    beginResetModel();
    m_paths.clear();
    endResetModel();
    save();
    emit countChanged();
}

QString ShelfModel::iconKey(const QString& path)
{
    // Stable across launches (unlike qHash, which is seeded per process).
    return QStringLiteral("f") + QString::fromLatin1(
        QCryptographicHash::hash(path.toUtf8(), QCryptographicHash::Md5).toHex().left(16));
}

QString ShelfModel::sizeText(qint64 bytes)
{
    static const char* const units[] = { "Б", "КБ", "МБ", "ГБ", "ТБ" };
    double value = double(bytes);
    int unit = 0;
    while (value >= 1024.0 && unit < 4) {
        value /= 1024.0;
        ++unit;
    }
    const int decimals = (unit == 0 || value >= 100.0) ? 0 : 1;
    return QString::number(value, 'f', decimals) + QLatin1Char(' ') + QString::fromUtf8(units[unit]);
}

void ShelfModel::load()
{
    const QStringList stored = QSettings().value(m_settingsKey).toStringList();
    QStringList valid;
    for (const QString& p : stored) {
        if (QFileInfo::exists(p) && !valid.contains(p))
            valid << p;
    }
    m_paths = valid.mid(0, kMaxItems);
    if (valid != stored)
        save();
}

void ShelfModel::save() const
{
    QSettings().setValue(m_settingsKey, m_paths);
}
