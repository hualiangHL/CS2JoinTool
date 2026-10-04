


#ifndef QQMLTREEROW_P_H
#define QQMLTREEROW_P_H












#include <QtQmlModels/private/qtqmlmodelsglobal_p.h>

#include <QtCore/qmap.h>
#include <QtCore/qvariant.h>

#include <memory>
#include <vector>

QT_REQUIRE_CONFIG(qml_tree_model);

QT_BEGIN_NAMESPACE

class QQmlTreeRow
{
public:
    explicit QQmlTreeRow(QQmlTreeRow *parentItem = nullptr);
    explicit QQmlTreeRow(const QVariant &data, QQmlTreeRow *parentItem = nullptr);
    explicit QQmlTreeRow(const QVariantMap &data, QQmlTreeRow *parentItem = nullptr);

    QQmlTreeRow *parent() const { return m_parent; }
    void setParent(QQmlTreeRow *parent) { m_parent = parent; }

    const QQmlTreeRow *getRow(int i) const { return m_children[i].get(); }
    void addChild(QQmlTreeRow *child);
    size_t rowCount() const { return m_children.size(); }
    int subTreeSize() const;

    QVariantMap data() const { return dataMap; }
    QVariant data(const QString &key) const { return dataMap[key]; }
    const std::vector<std::unique_ptr<QQmlTreeRow>>& children() const { return m_children; }
    void removeChild(std::vector<std::unique_ptr<QQmlTreeRow>>::const_iterator &child);
    void removeChildAt(int i);
    void setData(const QVariant &data);
    void setData(const QVariantMap &data);
    void setField(const QString &key, const QVariant &value);
    QVariant toVariant() const;
private:
    void unpackVariantMap(const QVariantMap &dataMap);

    QQmlTreeRow *m_parent;
    std::vector<std::unique_ptr<QQmlTreeRow>> m_children;
    QVariantMap dataMap;
};

QT_END_NAMESPACE

#endif
