#include "ImageStore.h"

#include <QMutexLocker>

void ImageStore::put(const QString& key, const QImage& image)
{
    QMutexLocker lock(&m_mutex);
    m_images.insert(key, image);
}

QImage ImageStore::get(const QString& key) const
{
    QMutexLocker lock(&m_mutex);
    return m_images.value(key);
}

bool ImageStore::contains(const QString& key) const
{
    QMutexLocker lock(&m_mutex);
    return m_images.contains(key);
}

void ImageStore::remove(const QString& key)
{
    QMutexLocker lock(&m_mutex);
    m_images.remove(key);
}

ImageProvider::ImageProvider(std::shared_ptr<ImageStore> store)
    : QQuickImageProvider(QQuickImageProvider::Image)
    , m_store(std::move(store))
{
}

QImage ImageProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize)
{
    QImage image = m_store->get(id);
    if (!image.isNull() && requestedSize.width() > 0 && requestedSize.height() > 0
        && (image.width() > requestedSize.width() || image.height() > requestedSize.height()))
        image = image.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    if (size)
        *size = image.size();
    return image;
}
