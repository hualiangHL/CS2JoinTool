



#include "qqmlabstractcolumnmodel_p.h"

#include <QtCore/qloggingcategory.h>

#include <QtQml/qqmlinfo.h>
#include <QtQml/qqmlengine.h>

QT_BEGIN_NAMESPACE

using namespace Qt::StringLiterals;

Q_LOGGING_CATEGORY(lcColumnModel, "qt.qml.columnmodel")

QQmlAbstractColumnModel::QQmlAbstractColumnModel(QObject *parent)
    : QAbstractItemModel(parent)
{
}

QQmlListProperty<QQmlTableModelColumn> QQmlAbstractColumnModel::columns()
{
    return {this, nullptr,
             &QQmlAbstractColumnModel::columns_append,
             &QQmlAbstractColumnModel::columns_count,
             &QQmlAbstractColumnModel::columns_at,
             &QQmlAbstractColumnModel::columns_clear,
             &QQmlAbstractColumnModel::columns_replace,
             &QQmlAbstractColumnModel::columns_removeLast};
}

void QQmlAbstractColumnModel::columns_append(QQmlListProperty<QQmlTableModelColumn> *property,
                                   QQmlTableModelColumn *value)
{
    auto *model = static_cast<QQmlAbstractColumnModel *>(property->object);
    Q_ASSERT(value);
    Q_ASSERT(model);
    auto *column = qobject_cast<QQmlTableModelColumn *>(value);
    if (column)
        model->mColumns.append(column);
}

qsizetype QQmlAbstractColumnModel::columns_count(QQmlListProperty<QQmlTableModelColumn> *property)
{
    auto *model = static_cast<QQmlAbstractColumnModel*>(property->object);
    Q_ASSERT(model);
    return model->mColumns.size();
}

QQmlTableModelColumn *QQmlAbstractColumnModel::columns_at(QQmlListProperty<QQmlTableModelColumn> *property, qsizetype index)
{
    auto *model = static_cast<QQmlAbstractColumnModel*>(property->object);
    Q_ASSERT(model);
    return model->mColumns.at(index);
}

void QQmlAbstractColumnModel::columns_clear(QQmlListProperty<QQmlTableModelColumn> *property)
{
    auto *model = static_cast<QQmlAbstractColumnModel *>(property->object);
    Q_ASSERT(model);
    return model->mColumns.clear();
}

void QQmlAbstractColumnModel::columns_replace(QQmlListProperty<QQmlTableModelColumn> *property, qsizetype index, QQmlTableModelColumn *value)
{
    auto *model = static_cast<QQmlAbstractColumnModel *>(property->object);
    Q_ASSERT(model);
    if (auto *column = qobject_cast<QQmlTableModelColumn *>(value))
        return model->mColumns.replace(index, column);
}

void QQmlAbstractColumnModel::columns_removeLast(QQmlListProperty<QQmlTableModelColumn> *property)
{
    auto *model = static_cast<QQmlAbstractColumnModel *>(property->object);
    Q_ASSERT(model);
    model->mColumns.removeLast();
}

QVariant QQmlAbstractColumnModel::data(const QModelIndex &index, const QString &role) const
{
    const int iRole = mRoleNames.key(role.toUtf8(), -1);
    if (iRole >= 0)
        return data(index, iRole);
    return {};
}

QVariant QQmlAbstractColumnModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        qmlWarning(this) << "data(): invalid QModelIndex";
        return {};
    }

    const int row = index.row();
    if (row < 0 || row >= rowCount(parent(index))) {
        qmlWarning(this) << "data(): invalid row specified in QModelIndex";
        return {};
    }

    const int column = index.column();
    if (column < 0 || column >= columnCount(parent(index))) {
        qmlWarning(this) << "data(): invalid column specified in QModelIndex";
        return {};
    }

    const ColumnMetadata columnMetadata = mColumnMetadata.at(column);
    const QString roleName = QString::fromUtf8(mRoleNames.value(role));
    if (!columnMetadata.roles.contains(roleName)) {
        qmlWarning(this) << "data(): no role named " << roleName
                         << " at column index " << column << ". The available roles for that column are: "
                         << columnMetadata.roles.keys();
        return {};
    }

    const ColumnRoleMetadata roleData = columnMetadata.roles.value(roleName);
    if (roleData.columnRole == ColumnRole::StringRole) {

        return dataPrivate(index, roleName);
    }



    QJSValue getter = mColumns.at(column)->getterAtRole(roleName);


    const auto args = QJSValueList() << qmlEngine(this)->toScriptValue(index);
    return getter.call(args).toVariant();
}

bool QQmlAbstractColumnModel::setData(const QModelIndex &index, const QVariant &value, const QString &role)
{
    const int intRole = mRoleNames.key(role.toUtf8(), -1);
    if (intRole >= 0)
        return setData(index, value, intRole);
    return false;
}

bool QQmlAbstractColumnModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    Q_ASSERT(index.isValid());

    const int row = index.row();
    if (row < 0 || row >= rowCount(parent(index)))
        return false;

    const int column = index.column();
    if (column < 0 || column >= columnCount(parent(index)))
        return false;

    const QString roleName = QString::fromUtf8(mRoleNames.value(role));

    qCDebug(lcColumnModel).nospace() << "setData() called with index "
        << index << ", value " << value << " and role " << roleName;


    const ColumnMetadata columnMetadata = mColumnMetadata.at(index.column());
    if (!columnMetadata.roles.contains(roleName)) {
        qmlWarning(this) << "setData(): no role named \"" << roleName
                         << "\" at column index " << column << ". The available roles for that column are: "
                         << columnMetadata.roles.keys();
        return false;
    }



    const ColumnRoleMetadata roleData = columnMetadata.roles.value(roleName);
    QVariant effectiveValue = value;
    if (value.userType() != roleData.type) {
        if (!value.canConvert(QMetaType(roleData.type))) {
            qmlWarning(this).nospace() << "setData(): the value " << value
                                       << " set at row " << row << " column " << column << " with role " << roleName
                                       << " cannot be converted to " << roleData.typeName;
            return false;
        }

        if (!effectiveValue.convert(QMetaType(roleData.type))) {
            qmlWarning(this).nospace() << "setData(): failed converting value " << value
                                       << " set at row " << row << " column " << column << " with role " << roleName
                                       << " to " << roleData.typeName;
            return false;
        }
    }

    if (roleData.columnRole == ColumnRole::StringRole) {

        setDataPrivate(index, roleData.name, value);
    } else {
        qmlWarning(this).nospace() << "setData(): manipulation of complex row "
                                   << "structures is not supported";
        return false;
    }

    QVector<int> rolesChanged;
    rolesChanged.append(role);
    emit dataChanged(index, index, rolesChanged);
    emit rowsChanged();

    return true;
}

QHash<int, QByteArray> QQmlAbstractColumnModel::roleNames() const
{
    return mRoleNames;
}

Qt::ItemFlags QQmlAbstractColumnModel::flags(const QModelIndex &index) const
{
    Q_UNUSED(index)
    return Qt::ItemIsSelectable | Qt::ItemIsEnabled | Qt::ItemIsEditable;
}

void QQmlAbstractColumnModel::classBegin()
{
}

void QQmlAbstractColumnModel::componentComplete()
{
    mComponentCompleted = true;

    mColumnCount = mColumns.size();
    if (mColumnCount > 0)
        emit columnCountChanged();

    setInitialRows();
}


QQmlAbstractColumnModel::ColumnRoleMetadata::ColumnRoleMetadata()
    = default;

QQmlAbstractColumnModel::ColumnRoleMetadata::ColumnRoleMetadata(
    ColumnRole role, QString name, int type, QString typeName) :
    columnRole(role),
    name(std::move(name)),
    type(type),
    typeName(std::move(typeName))
{
}

bool QQmlAbstractColumnModel::ColumnRoleMetadata::isValid() const
{
    return !name.isEmpty();
}

QQmlAbstractColumnModel::ColumnRoleMetadata QQmlAbstractColumnModel::fetchColumnRoleData(const QString &roleNameKey,
                                                                       QQmlTableModelColumn *tableModelColumn, int columnIndex) const
{
    const QVariant row = firstRow();
    ColumnRoleMetadata roleData;

    QJSValue columnRoleGetter = tableModelColumn->getterAtRole(roleNameKey);
    if (columnRoleGetter.isUndefined()) {

        return roleData;
    }

    if (columnRoleGetter.isString()) {

        if (row.userType() != QMetaType::QVariantMap) {
            qmlWarning(this).quote() << "expected row for role "
                                     << roleNameKey << " of TableModelColumn at index "
                                     << columnIndex << " to be a simple object, but it's "
                                     << row.typeName() << " instead: " << row;
            return roleData;
        }
        const QString rolePropertyName = columnRoleGetter.toString();
        const QVariant roleProperty = row.toMap().value(rolePropertyName);

        roleData.columnRole = ColumnRole::StringRole;
        roleData.name = rolePropertyName;
        roleData.type = roleProperty.userType();
        roleData.typeName = QString::fromLatin1(roleProperty.typeName());
    } else if (columnRoleGetter.isCallable()) {


        const auto modelIndex = index(0, columnIndex);
        const auto args = QJSValueList() << qmlEngine(this)->toScriptValue(modelIndex);
        const QVariant cellData = columnRoleGetter.call(args).toVariant();



        roleData.columnRole = ColumnRole::FunctionRole;
        roleData.type = cellData.userType();
        roleData.typeName = QString::fromLatin1(cellData.typeName());
    } else {

        qmlWarning(this) << "TableModelColumn role for column at index "
                         << columnIndex << " must be either a string or a function; actual type is: "
                         << columnRoleGetter.toString();
    }

    return roleData;
}

void QQmlAbstractColumnModel::fetchColumnMetadata()
{
    qCDebug(lcColumnModel) << "gathering metadata for" << mColumnCount << "columns from first row:";

    static const auto supportedRoleNames = QQmlTableModelColumn::supportedRoleNames();




    for (int columnIndex = 0; columnIndex < mColumns.size(); ++columnIndex) {
        QQmlTableModelColumn *column = mColumns.at(columnIndex);
        qCDebug(lcColumnModel).nospace() << "- column " << columnIndex << ":";

        ColumnMetadata metaData;
        const auto builtInRoleKeys = supportedRoleNames.keys();
        for (const int builtInRoleKey : builtInRoleKeys) {
            const QString builtInRoleName = supportedRoleNames.value(builtInRoleKey);
            ColumnRoleMetadata roleData = fetchColumnRoleData(builtInRoleName, column, columnIndex);
            if (roleData.type == QMetaType::UnknownType) {

                continue;
            }

            qCDebug(lcColumnModel).nospace() << "  - added metadata for built-in role "
                                            << builtInRoleName << " at column index " << columnIndex
                                            << ": name=" << roleData.name << " typeName=" << roleData.typeName
                                            << " type=" << roleData.type;


            metaData.roles.insert(builtInRoleName, roleData);

            mRoleNames[builtInRoleKey] = builtInRoleName.toLatin1();
        }
        mColumnMetadata.insert(columnIndex, metaData);
    }
}

bool QQmlAbstractColumnModel::validateRowType(QLatin1StringView functionName, const QVariant &row) const
{
    if (!row.canConvert<QJSValue>()) {
        qmlWarning(this) << functionName << ": expected \"row\" argument to be a QJSValue,"
                         << " but got " << row.typeName() << " instead:\n" << row;
        return false;
    }

    const auto rowAsJSValue = row.value<QJSValue>();
    if (!rowAsJSValue.isObject() && !rowAsJSValue.isArray()) {
        qmlWarning(this) << functionName << ": expected \"row\" argument "
                         << "to be an object or array, but got:\n" << rowAsJSValue.toString();
        return false;
    }

    return true;
}

bool QQmlAbstractColumnModel::validateNewRow(QLatin1StringView functionName, const QVariant &row,
                                   NewRowOperationFlag operation) const
{
    if (mColumnMetadata.isEmpty()) {



        return true;
    }

    const bool isVariantMap = (row.userType() == QMetaType::QVariantMap);



    if (operation != SetRowsOperation && (!isVariantMap && !validateRowType(functionName, row)))
        return false;

    const QVariant rowAsVariant = operation == SetRowsOperation || isVariantMap
        ? row : row.value<QJSValue>().toVariant();
    if (rowAsVariant.userType() != QMetaType::QVariantMap) {
        qmlWarning(this) << functionName << ": row manipulation functions "
                         << "do not support complex rows";
        return false;
    }

    const QVariantMap rowAsMap = rowAsVariant.toMap();
    const int columnCount = rowAsMap.size();
    if (columnCount < mColumnCount) {
        qmlWarning(this) << functionName << ": expected " << mColumnCount
                         << " columns, but only got " << columnCount;
        return false;
    }



    for (int columnIndex = 0; columnIndex < mColumns.size(); ++columnIndex) {
        QQmlTableModelColumn *column = mColumns.at(columnIndex);
        const QHash<QString, QJSValue> getters = column->getters();
        const auto roleNames = getters.keys();
        const ColumnMetadata columnMetadata = mColumnMetadata.at(columnIndex);
        for (const QString &roleName : roleNames) {
            const ColumnRoleMetadata roleData = columnMetadata.roles.value(roleName);
            if (roleData.columnRole == ColumnRole::FunctionRole)
                continue;

            if (!rowAsMap.contains(roleData.name)) {
                qmlWarning(this).noquote() << functionName << ": expected a property named \""
                                           << roleData.name << "\" in row";
                return false;
            }

            const QVariant rolePropertyValue = rowAsMap.value(roleData.name);

            if (rolePropertyValue.userType() != roleData.type) {
                if (!rolePropertyValue.canConvert(QMetaType(roleData.type))) {
                    qmlWarning(this).noquote() << functionName << ": expected the property named \""
                                               << roleData.name << "\" to be of type \"" << roleData.typeName
                                               << "\", but got \"" << QString::fromLatin1(rolePropertyValue.typeName())
                                               << "\" instead";
                    return false;
                }

                QVariant effectiveValue = rolePropertyValue;
                if (!effectiveValue.convert(QMetaType(roleData.type))) {
                    qmlWarning(this).noquote() << functionName << ": failed converting value \""
                                               << rolePropertyValue << "\" set at column " << columnIndex << " with role \""
                                               << QString::fromLatin1(rolePropertyValue.typeName()) << "\" to \""
                                               << roleData.typeName << "\"";
                    return false;
                }
            }
        }
    }

    return true;
}


QT_END_NAMESPACE

#include "moc_qqmlabstractcolumnmodel_p.cpp"
