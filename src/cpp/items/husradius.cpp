






















#include "husradius.h"

#include <QtQml/QQmlInfo>

qreal HusRadius::all() const
{
    return m_all;
}

void HusRadius::setAll(qreal all)
{
    if (m_all == all)
        return;

    m_all = all;
    emit allChanged();

    if (m_topLeft < 0.)
        emit topLeftChanged();
    if (m_topRight < 0.)
        emit topRightChanged();
    if (m_bottomLeft < 0.)
        emit bottomLeftChanged();
    if (m_bottomRight < 0.)
        emit bottomRightChanged();
}

qreal HusRadius::topLeft() const
{
    if (m_topLeft >= 0.)
        return m_topLeft;

    return m_all;
}

void HusRadius::setTopLeft(qreal topLeft)
{
    if (m_topLeft == topLeft)
        return;

    if (topLeft < 0) {
        qmlWarning(this) << "topLeftRadius (" << topLeft << ") cannot be less than 0.";
        return;
    }

    m_topLeft = topLeft;
    emit topLeftChanged();
}

qreal HusRadius::topRight() const
{
    if (m_topRight >= 0.)
        return m_topRight;

    return m_all;
}

void HusRadius::setTopRight(qreal topRight)
{
    if (m_topRight == topRight)
        return;

    if (topRight < 0) {
        qmlWarning(this) << "topRightRadius (" << topRight << ") cannot be less than 0.";
        return;
    }

    m_topRight = topRight;
    emit topRightChanged();
}

qreal HusRadius::bottomLeft() const
{
    if (m_bottomLeft >= 0.)
        return m_bottomLeft;

    return m_all;
}

void HusRadius::setBottomLeft(qreal bottomLeft)
{
    if (m_bottomLeft == bottomLeft)
        return;

    if (bottomLeft < 0) {
        qmlWarning(this) << "bottomLeftRadius (" << bottomLeft << ") cannot be less than 0.";
        return;
    }

    m_bottomLeft = bottomLeft;
    emit bottomLeftChanged();
}

qreal HusRadius::bottomRight() const
{
    if (m_bottomRight >= 0.)
        return m_bottomRight;

    return m_all;
}

void HusRadius::setBottomRight(qreal bottomRight)
{
    if (m_bottomRight == bottomRight)
        return;

    if (bottomRight < 0) {
        qmlWarning(this) << "bottomRightRadius (" << bottomRight << ") cannot be less than 0.";
        return;
    }

    m_bottomRight = bottomRight;
    emit bottomRightChanged();
}