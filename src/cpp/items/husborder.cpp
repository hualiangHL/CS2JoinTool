






















#include "husborder.h"

HusBorder::HusBorder(QObject *parent)
    : QQuickPen(parent)
{
}

HusBorder::~HusBorder()
{

}

int HusBorder::style() const
{
    return m_style;
}

void HusBorder::setStyle(int style)
{
    if (m_style == style && QQuickPen::isValid())
        return;

    m_style = style;
    static_cast<QQuickItem*>(parent())->update();

    emit styleChanged();
}
