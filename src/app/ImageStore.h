#pragma once

#include <QHash>
#include <QImage>
#include <QMutex>
#include <QQuickImageProvider>

#include <memory>

// Images produced on the GUI thread (AppKit), served to QML's loader threads:
//   image://img/art<N>   — album artwork
//   image://img/f<hash>  — Finder icon of a shelf file
class ImageStore {
public:
    void put(const QString& key, const QImage& image);
    QImage get(const QString& key) const;
    bool contains(const QString& key) const;
    void remove(const QString& key);

private:
    mutable QMutex m_mutex;
    QHash<QString, QImage> m_images;
};

class ImageProvider : public QQuickImageProvider {
public:
    explicit ImageProvider(std::shared_ptr<ImageStore> store);
    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override;

private:
    std::shared_ptr<ImageStore> m_store;
};
