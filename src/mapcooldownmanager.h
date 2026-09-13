#ifndef MAPCOOLDOWNMANAGER_H
#define MAPCOOLDOWNMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class MapCooldownManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList filteredMaps READ filteredMaps NOTIFY filteredMapsChanged)
    Q_PROPERTY(QString searchText READ searchText WRITE setSearchText NOTIFY searchTextChanged)
    Q_PROPERTY(bool onlyCooling READ onlyCooling WRITE setOnlyCooling NOTIFY onlyCoolingChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY totalCountChanged)

public:
    explicit MapCooldownManager(QObject *parent = nullptr);

    QVariantList filteredMaps() const { return m_filteredMaps; }
    QString searchText() const { return m_searchText; }
    void setSearchText(const QString &text);
    bool onlyCooling() const { return m_onlyCooling; }
    void setOnlyCooling(bool only);
    bool loading() const { return m_loading; }
    QString error() const { return m_error; }
    int totalCount() const { return m_allMaps.size(); }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE QString getMapDifficulty(const QString &mapName);

signals:
    void filteredMapsChanged();
    void searchTextChanged();
    void onlyCoolingChanged();
    void loadingChanged();
    void errorChanged();
    void totalCountChanged();

private slots:
    void onReplyFinished();

private:
    QNetworkAccessManager *m_manager;
    QNetworkReply *m_currentReply = nullptr;
    QVariantList m_allMaps;
    QVariantList m_filteredMaps;
    QString m_searchText;
    bool m_onlyCooling = false;
    bool m_loading = false;
    QString m_error;

    void applyFilter();
    static QString formatCooldown(int minutes);
};

#endif 
