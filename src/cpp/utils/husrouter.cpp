






















#include "husrouter.h"

class HusRouterPrivate
{
public:
    QUrl m_currentUrl;
    int m_currentIndex = -1;
    QList<HusRouterHistory*> m_history;
    int m_historyMaxCount = 100;
};

HusRouter::HusRouter(QObject *parent)
    : QObject{parent}
    , d_ptr(new HusRouterPrivate)
{

}

HusRouter::~HusRouter()
{
    clear();
}

QUrl HusRouter::currentUrl() const
{
    Q_D(const HusRouter);

    return d->m_currentUrl;
}

QString HusRouter::currentPath() const
{
    Q_D(const HusRouter);

    return d->m_currentUrl.path();
}

int HusRouter::currentIndex() const
{
    Q_D(const HusRouter);

    return d->m_currentIndex;
}

QQmlListProperty<HusRouterHistory> HusRouter::history()
{
    Q_D(HusRouter);

    return QQmlListProperty<HusRouterHistory>(this, &d->m_history);
}

int HusRouter::historyMaxCount() const
{
    Q_D(const HusRouter);

    return d->m_historyMaxCount;
}

void HusRouter::setHistoryMaxCount(int maxCount)
{
    Q_D(HusRouter);

    if (maxCount < 0 || d->m_historyMaxCount == maxCount)
        return;

    d->m_historyMaxCount = maxCount;
    
    
    while (d->m_history.size() > d->m_historyMaxCount) {
        d->m_history.takeFirst()->deleteLater();
        d->m_currentIndex--;
    }
    
    
    if (d->m_currentIndex < 0) {
        d->m_currentUrl = "";
        d->m_currentIndex = -1;
    } else if (d->m_currentIndex >= d->m_history.size()) {
        d->m_currentIndex = d->m_history.size() - 1;
        d->m_currentUrl = d->m_history[d->m_currentIndex]->location();
    }
    
    if (d->m_history.isEmpty() || d->m_currentIndex < 0) {
        d->m_currentUrl = "";
        d->m_currentIndex = -1;
        emit currentUrlChanged();
        emit currentPathChanged();
        emit currentIndexChanged();
    }
    
    emit historyMaxCountChanged();
    emit historyChanged();
}

bool HusRouter::canGoBack() const
{
    Q_D(const HusRouter);

    return d->m_currentIndex > 0 && d->m_history.size() > 0;
}

bool HusRouter::canGoForward() const
{
    Q_D(const HusRouter);

    return d->m_currentIndex < d->m_history.size() - 1;
}

void HusRouter::push(const QUrl &url)
{
    Q_D(HusRouter);

    if (url.isEmpty() || url == d->m_currentUrl)
        return;

    d->m_currentUrl = url;

    
    if (d->m_currentIndex + 1 < d->m_history.size()) {
        for (int i = d->m_currentIndex + 1; i < d->m_history.size(); ++i) {
            d->m_history[i]->deleteLater();
        }
        d->m_history.erase(d->m_history.begin() + d->m_currentIndex + 1, d->m_history.end());
    }

    
    d->m_currentIndex++;
    d->m_history.append(new HusRouterHistory{ url, this });

    
    while (d->m_history.size() > d->m_historyMaxCount) {
        d->m_history.takeFirst()->deleteLater();
        d->m_currentIndex--;
    }

    emit currentUrlChanged();
    emit currentPathChanged();
    emit currentIndexChanged();
    emit historyChanged();
    emit canGoBackChanged();
    emit canGoForwardChanged();
}

void HusRouter::replace(const QUrl &url)
{
    Q_D(HusRouter);

    if (url.isEmpty()) return;

    if (url == d->m_currentUrl || d->m_currentIndex < 0 || d->m_currentIndex >= d->m_history.size())
        return;

    d->m_history[d->m_currentIndex]->setLocation(url);
    d->m_currentUrl = url;

    emit currentUrlChanged();
    emit currentPathChanged();
}

void HusRouter::clear()
{
    Q_D(HusRouter);

    for (auto &history: d->m_history) {
        history->deleteLater();
    }

    d->m_history.clear();
    d->m_currentUrl = "";
    d->m_currentIndex = -1;

    emit currentUrlChanged();
    emit currentPathChanged();
    emit currentIndexChanged();
    emit historyChanged();
    emit canGoBackChanged();
    emit canGoForwardChanged();
}

void HusRouter::goBack()
{
    Q_D(HusRouter);

    if (canGoBack()) {
        d->m_currentUrl = d->m_history[--d->m_currentIndex]->location();
        emit currentUrlChanged();
        emit currentPathChanged();
        emit currentIndexChanged();
        emit canGoBackChanged();
        emit canGoForwardChanged();
    }
}

void HusRouter::goForward()
{
    Q_D(HusRouter);

    if (canGoForward()) {
        d->m_currentUrl = d->m_history[++d->m_currentIndex]->location();
        emit currentUrlChanged();
        emit currentPathChanged();
        emit currentIndexChanged();
        emit canGoBackChanged();
        emit canGoForwardChanged();
    }
}

QVariantMap HusRouter::getQueryParams(const QUrl &url) const
{
    Q_D(const HusRouter);

    QVariantMap map;
    const auto items = QUrlQuery(url).queryItems();
    for (const auto &item : items) {
        map.insert(item.first, item.second);
    }

    return map;
}
