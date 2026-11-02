#pragma once

#include <QQuickItem>

class QSGNode;

class RoundedClip : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(qreal radius READ radius WRITE setRadius NOTIFY radiusChanged)

public:
    explicit RoundedClip(QQuickItem *parent = nullptr);

    qreal radius() const;
    void setRadius(qreal radius);

signals:
    void radiusChanged();

protected:
    QSGNode *updatePaintNode(
        QSGNode *oldNode,
        UpdatePaintNodeData *data
    ) override;

    void geometryChange(
        const QRectF &newGeometry,
        const QRectF &oldGeometry
    ) override;

private:
    qreal m_radius = 20.0;
};
