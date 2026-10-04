



#include "qqmltreemodel_p.h"
#include "qqmltreerow_p.h"

#include <QtCore/qloggingcategory.h>

#include <QtQml/qqmlinfo.h>
#include <QtQml/qqmlengine.h>

QT_BEGIN_NAMESPACE

using namespace Qt::StringLiterals;

static const QString ROWS_PROPERTY_NAME = u"rows"_s;











































QQmlTreeModel::QQmlTreeModel(QObject *parent)
    : QQmlAbstractColumnModel(parent)
{
}

QQmlTreeModel::~QQmlTreeModel() = default;








QVariant QQmlTreeModel::rows() const
{
    QVariantList rowsAsVariant;
    for (const auto &row : mRows)
        rowsAsVariant.append(row->toVariant());

    return rowsAsVariant;
}

void QQmlTreeModel::setRows(const QVariant &rows)
{
    if (rows.userType() != qMetaTypeId<QJSValue>()) {
        qmlWarning(this) << "setRows(): \"rows\" must be an array; actual type is " << rows.typeName();
        return;
    }

    const auto rowsAsJSValue = rows.value<QJSValue>();
    const QVariantList rowsAsVariantList = rowsAsJSValue.toVariant().toList();

    if (!mComponentCompleted) {

        mInitialRows = rowsAsVariantList;
        return;
    }

    setRowsPrivate(rowsAsVariantList);
}

void QQmlTreeModel::setRowsPrivate(const QVariantList &rowsAsVariantList)
{
    Q_ASSERT(mComponentCompleted);


    if (mColumns.isEmpty()) {
        qmlWarning(this) << "No TableModelColumns were set; model will be empty";
        return;
    }

    const bool firstTimeValidRowsHaveBeenSet = mColumnMetadata.isEmpty();
    if (!firstTimeValidRowsHaveBeenSet) {

        for (const auto &row : rowsAsVariantList) {


            const QVariant wrappedRow = QVariant::fromValue(row);
            if (!validateNewRow("TreeModel::setRows"_L1, wrappedRow, SetRowsOperation))
                return;
        }
    }

    beginResetModel();



    mRows.clear();

    for (const auto &rowAsVariant : rowsAsVariantList)
        mRows.push_back(std::make_unique<QQmlTreeRow>(rowAsVariant));



    if (firstTimeValidRowsHaveBeenSet && (!mRows.empty() || !mInitialRows.isEmpty()))
        fetchColumnMetadata();

    endResetModel();
    emit rowsChanged();
}

QVariant QQmlTreeModel::dataPrivate(const QModelIndex &index, const QString &roleName) const
{
    const ColumnMetadata columnMetadata = mColumnMetadata.at(index.column());
    const QString propertyName = columnMetadata.roles.value(roleName).name;
    const auto *thisRow = static_cast<const QQmlTreeRow *>(index.internalPointer());
    return thisRow->data(propertyName);
}

void QQmlTreeModel::setDataPrivate(const QModelIndex &index, const QString &roleName, QVariant value)
{
    auto *row = static_cast<QQmlTreeRow *>(index.internalPointer());
    row->setField(roleName, value);
}





































void QQmlTreeModel::appendRow(QModelIndex parent, const QVariant &row)
{
    if (!validateNewRow("TreeModel::appendRow"_L1, row))
        return;

    const QVariant data = row.userType() == QMetaType::QVariantMap ? row : row.value<QJSValue>().toVariant();

    if (parent.isValid()) {
        auto *parentRow = static_cast<QQmlTreeRow *>(parent.internalPointer());
        auto *newChild = new QQmlTreeRow(data);

        beginInsertRows(parent, static_cast<int>(parentRow->rowCount()), static_cast<int>(parentRow->rowCount()));
        parentRow->addChild(newChild);


        if (mColumnMetadata.isEmpty())
            fetchColumnMetadata();

        endInsertRows();
    } else {
        qmlWarning(this) << "append: could not find any node at the specified index"
                         << " - the new row will be appended to root";

        beginInsertRows(QModelIndex(),
                        static_cast<int>(mRows.size()),
                        static_cast<int>(mRows.size()));

        mRows.push_back(std::make_unique<QQmlTreeRow>(data));


        if (mColumnMetadata.isEmpty())
            fetchColumnMetadata();

        endInsertRows();
    }

    emit rowsChanged();
}








void QQmlTreeModel::appendRow(const QVariant &row)
{
    appendRow({}, row);
}








void QQmlTreeModel::clear()
{
    QQmlEngine *engine = qmlEngine(this);
    Q_ASSERT(engine);
    setRows(QVariant::fromValue(engine->newArray()));
}











QVariant QQmlTreeModel::getRow(const QModelIndex &rowIndex) const
{
    if (rowIndex.isValid())
        return static_cast<QQmlTreeRow*>(rowIndex.internalPointer())->toVariant();

    qmlWarning(this) << "getRow: could not find any node at the specified index";
    return {};
}

QVariant QQmlTreeModel::firstRow() const
{
    return mRows.front().get()->data();
}

void QQmlTreeModel::setInitialRows()
{
    setRowsPrivate(mInitialRows);
}












void QQmlTreeModel::removeRow(QModelIndex rowIndex)
{
    if (rowIndex.isValid()) {
        QModelIndex mIndexParent = rowIndex.parent();

        beginRemoveRows(mIndexParent, rowIndex.row(), rowIndex.row());

        if (mIndexParent.isValid()) {
            auto *parent = static_cast<QQmlTreeRow *>(mIndexParent.internalPointer());
            parent->removeChildAt(rowIndex.row());
        } else {
            mRows.erase(std::next(mRows.begin(), rowIndex.row()));
        }

        endRemoveRows();
    } else {
        qmlWarning(this) << "TreeModel::removeRow could not find any node at the specified index";
        return;
    }

    emit rowsChanged();
}

























void QQmlTreeModel::setRow(QModelIndex rowIndex, const QVariant &rowData)
{
    if (!rowIndex.isValid()) {
        qmlWarning(this) << "TreeModel::setRow: invalid modelIndex";
        return;
    }

    const QVariantMap rowAsMap = rowData.toMap();
    if (rowAsMap.contains(ROWS_PROPERTY_NAME) && rowAsMap[ROWS_PROPERTY_NAME].userType() == QMetaType::Type::QVariantList) {
        qmlWarning(this) << "TreeModel::setRow: child rows are not allowed";
        return;
    }

    if (!validateNewRow("TreeModel::setRow"_L1, rowData))
        return;

    const QVariant rowAsVariant = rowData.userType() == QMetaType::QVariantMap ? rowData : rowData.value<QJSValue>().toVariant();
    auto *row = static_cast<QQmlTreeRow *>(rowIndex.internalPointer());
    row->setData(rowAsVariant);

    const QModelIndex topLeftModelIndex(createIndex(rowIndex.row(), 0, rowIndex.internalPointer()));
    const QModelIndex bottomRightModelIndex(createIndex(rowIndex.row(), mColumnCount-1, rowIndex.internalPointer()));

    emit dataChanged(topLeftModelIndex, bottomRightModelIndex);
    emit rowsChanged();
}










QModelIndex QQmlTreeModel::index(int row, int column, const QModelIndex &parent) const
{
    if (!parent.isValid()){
        if (static_cast<size_t>(row) >= mRows.size())
            return {};

        return createIndex(row, column, mRows.at(row).get());
    }

    const auto *treeRow = static_cast<const QQmlTreeRow *>(parent.internalPointer());
    if (treeRow->rowCount() <= static_cast<size_t>(row))
        return {};

    return createIndex(row, column, treeRow->getRow(row));
}













































QModelIndex QQmlTreeModel::index(const std::vector<int> &treeIndex, int column)
{
    QModelIndex mIndex;
    QQmlTreeRow *row = getPointerToTreeRow(mIndex, treeIndex);

    if (row)
        return createIndex(treeIndex.back(), column, row);

    qmlWarning(this) << "TreeModel::index: could not find any node at the specified index";
    return {};
}

QModelIndex QQmlTreeModel::parent(const QModelIndex &index) const
{
    if (!index.isValid())
        return {};

    const auto *thisRow = static_cast<const QQmlTreeRow *>(index.internalPointer());
    const QQmlTreeRow *parentRow = thisRow->parent();

    if (!parentRow)
        return {};

    const QQmlTreeRow *grandparentRow = parentRow->parent();

    if (!grandparentRow) {
        for (size_t i = 0; i < mRows.size(); i++) {
            if (mRows[i].get() == parentRow)
                return createIndex(static_cast<int>(i), 0, parentRow);
        }
        Q_UNREACHABLE_RETURN(QModelIndex());
    }

    for (size_t i = 0; i < grandparentRow->rowCount(); i++) {
        if (grandparentRow->getRow(static_cast<int>(i)) == parentRow)
            return createIndex(static_cast<int>(i), 0, parentRow);
    }
    Q_UNREACHABLE_RETURN(QModelIndex());
}


int QQmlTreeModel::rowCount(const QModelIndex &parent) const
{
    if (!parent.isValid())
        return static_cast<int>(mRows.size());

    const auto *row = static_cast<const QQmlTreeRow *>(parent.internalPointer());
    return static_cast<int>(row->rowCount());
}











int QQmlTreeModel::columnCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);

    return mColumnCount;
}



















bool QQmlTreeModel::validateNewRow(QLatin1StringView functionName, const QVariant &row,
                                   NewRowOperationFlag operation) const
{
    const bool isVariantMap = (row.userType() == QMetaType::QVariantMap);
    const QVariant rowAsVariant = operation == SetRowsOperation || isVariantMap
        ? row : row.value<QJSValue>().toVariant();
    const QVariantMap rowAsMap = rowAsVariant.toMap();
    if (rowAsMap.contains(ROWS_PROPERTY_NAME) && rowAsMap[ROWS_PROPERTY_NAME].userType() == QMetaType::Type::QVariantList)
    {
        const QList<QVariant> variantList = rowAsMap[ROWS_PROPERTY_NAME].toList();
        for (const QVariant &rowAsVariant : variantList)
            if (!validateNewRow(functionName, rowAsVariant))
                return false;
    }

    return QQmlAbstractColumnModel::validateNewRow(functionName, row, operation);
}

int QQmlTreeModel::treeSize() const
{
    int treeSize = 0;

    for (const auto &treeRow : mRows)
        treeSize += treeRow->subTreeSize();

    return treeSize;
}

QQmlTreeRow *QQmlTreeModel::getPointerToTreeRow(QModelIndex &modIndex,
                                                const std::vector<int> &rowIndex) const
{
    for (int r : rowIndex) {
        modIndex = index(r, 0, modIndex);
        if (!modIndex.isValid())
            return nullptr;
    }

    return static_cast<QQmlTreeRow*>(modIndex.internalPointer());
}

QT_END_NAMESPACE

#include "moc_qqmltreemodel_p.cpp"
