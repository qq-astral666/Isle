#pragma once

#include <QAbstractListModel>
#include <QStringList>
#include <QUrl>

// Files "parked" in the notch. Stores references (paths), not copies, and
// remembers them between launches. Newest first.
class ShelfModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Role {
        PathRole = Qt::UserRole + 1,
        NameRole,
        UrlRole,
        IsDirRole,
        SizeTextRole,
        IconKeyRole,
    };

    static constexpr int kMaxItems = 30;

    explicit ShelfModel(QString settingsKey, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = {}) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return int(m_paths.size()); }
    QStringList paths() const { return m_paths; }

    // Returns how many new files were added (duplicates move to the front).
    Q_INVOKABLE int addUrls(const QList<QUrl>& urls);
    int addPaths(const QStringList& paths);
    Q_INVOKABLE void remove(int row);
    Q_INVOKABLE void clear();

    static QString iconKey(const QString& path);
    static QString sizeText(qint64 bytes);

signals:
    void countChanged();

private:
    void load();
    void save() const;

    QString m_settingsKey;
    QStringList m_paths;
};
