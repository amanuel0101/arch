#include "roundedclip.h"

#include <QSGClipNode>
#include <QSGGeometry>
#include <QSGNode>
#include <QVector>
#include <QPointF>
#include <QtMath>

RoundedClip::RoundedClip(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

qreal RoundedClip::radius() const
{
    return m_radius;
}

void RoundedClip::setRadius(qreal radius)
{
    if (qFuzzyCompare(m_radius, radius))
        return;

    m_radius = qMax(0.0, radius);

    emit radiusChanged();
    update();
}

void RoundedClip::geometryChange(
    const QRectF &newGeometry,
    const QRectF &oldGeometry)
{
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    update();
}

QSGNode *RoundedClip::updatePaintNode(
    QSGNode *oldNode,
    UpdatePaintNodeData *)
{
    auto *clip = static_cast<QSGClipNode *>(oldNode);

    if (!clip) {
        clip = new QSGClipNode();
        clip->setFlag(QSGNode::OwnsGeometry, true);
    }

    const qreal w = width();
    const qreal h = height();

    if (w <= 0 || h <= 0) {
        clip->setIsRectangular(true);
        clip->setClipRect(QRectF());
        return clip;
    }

    const qreal r = qMin(m_radius, qMin(w, h) / 2.0);
    constexpr int segments = 12;

    QVector<QPointF> outline;

    const QPointF centers[] = {
        {r, r},
        {w - r, r},
        {w - r, h - r},
        {r, h - r}
    };

    const qreal starts[] = {180, 270, 0, 90};

    for (int corner = 0; corner < 4; ++corner) {
        for (int i = 0; i <= segments; ++i) {
            const qreal angle = qDegreesToRadians(
                starts[corner] + (90.0 * i / segments)
            );

            outline.append({
                centers[corner].x() + r * qCos(angle),
                centers[corner].y() + r * qSin(angle)
            });
        }
    }

    const int count = outline.size();
    const int vertexCount = count * 3;

    auto *geometry = new QSGGeometry(
        QSGGeometry::defaultAttributes_Point2D(),
        vertexCount
    );

    geometry->setDrawingMode(QSGGeometry::DrawTriangles);

    auto *vertices = geometry->vertexDataAsPoint2D();

    const QPointF center(w / 2.0, h / 2.0);

    for (int i = 0; i < count; ++i) {
        const QPointF &a = outline[i];
        const QPointF &b = outline[(i + 1) % count];

        const int v = i * 3;

        vertices[v].set(center.x(), center.y());
        vertices[v + 1].set(a.x(), a.y());
        vertices[v + 2].set(b.x(), b.y());
    }

    clip->setGeometry(geometry);
    clip->setIsRectangular(false);
    clip->setClipRect(QRectF(0, 0, w, h));

    return clip;
}
