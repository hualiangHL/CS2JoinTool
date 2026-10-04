#ifndef SQUEEZEENGINE_H
#define SQUEEZEENGINE_H

#include <QObject>
#include <QUdpSocket>
#include <QTimer>
#include <QHostAddress>
#include <QtQml/qqmlregistration.h>



class LangManager;
class SqueezeEngine : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(QString serverName READ serverName NOTIFY stateChanged)
    Q_PROPERTY(QString serverIp READ serverIp NOTIFY stateChanged)
    Q_PROPERTY(int serverPort READ serverPort NOTIFY stateChanged)
    Q_PROPERTY(int players READ players NOTIFY stateChanged)
    Q_PROPERTY(int maxPlayers READ maxPlayers NOTIFY stateChanged)
    Q_PROPERTY(QString mapName READ mapName NOTIFY stateChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(QString logText READ logText NOTIFY logTextChanged)
    Q_PROPERTY(int retryCount READ retryCount NOTIFY retryCountChanged)
    Q_PROPERTY(int intervalMs READ intervalMs WRITE setIntervalMs NOTIFY intervalMsChanged)
    Q_PROPERTY(int threshold READ threshold WRITE setThreshold NOTIFY thresholdChanged)
    Q_PROPERTY(int protocol READ protocol WRITE setProtocol NOTIFY protocolChanged)
    Q_PROPERTY(int coreCount READ coreCount WRITE setCoreCount NOTIFY coreCountChanged)
    Q_PROPERTY(int maxCores READ maxCores CONSTANT)
    Q_PROPERTY(bool suppressConnectToast READ suppressConnectToast WRITE setSuppressConnectToast NOTIFY suppressConnectToastChanged)

public:
    explicit SqueezeEngine(QObject *parent = nullptr);

    bool running() const { return m_running; }
    QString serverName() const { return m_serverName; }
    QString serverIp() const { return m_ip; }
    int serverPort() const { return m_port; }
    int players() const { return m_players; }
    int maxPlayers() const { return m_maxPlayers; }
    QString mapName() const { return m_map; }
    QString statusText() const { return m_status; }
    QString logText() const { return m_log; }
    int retryCount() const { return m_retry; }
    int intervalMs() const { return m_interval; }
    int threshold() const { return m_threshold; }
    int coreCount() const { return m_coreCount; }
    int maxCores() const { return m_maxCores; }
    bool suppressConnectToast() const { return m_suppressConnectToast; }
    void setSuppressConnectToast(bool v) {
        if (m_suppressConnectToast != v) {
            m_suppressConnectToast = v;
            emit suppressConnectToastChanged();
        }
    }

    void setIntervalMs(int v);
    void setThreshold(int v);
    void setCoreCount(int v);
    int protocol() const { return m_protocol; }
    void setProtocol(int v);


    void setLangManager(LangManager *l) { m_lang = l; }
    bool isEn() const;

    Q_INVOKABLE void start(const QString &ip, int port, const QString &name);
    Q_INVOKABLE void stop(bool manual = true);
    Q_INVOKABLE void joinNow();
    Q_INVOKABLE void probe(const QString &ip, int port, const QString &name);

signals:
    void runningChanged();
    void stateChanged();
    void statusTextChanged();
    void logTextChanged();
    void suppressConnectToastChanged();
    void retryCountChanged();
    void intervalMsChanged();
    void thresholdChanged();
    void protocolChanged();
    void coreCountChanged();
    void connectSent();

private:
    void appendLog(const QString &msg);
    void setStatus(const QString &s);
    void queryOnce();
    void onReadyRead();
    void onQueryTimeout();
    void sendQuery();
    QString readString(const QByteArray &data, int &off) const;
    void cleanup(QString &s) const;

    QUdpSocket m_socket;
    QTimer m_timer;
    QTimer m_queryTimer;
    bool m_running = false;
    QString m_ip;
    quint16 m_port = 0;
    QString m_serverName;
    int m_players = 0;
    int m_maxPlayers = 0;
    QString m_map;
    QString m_status;
    QString m_log;
    int m_retry = 0;
    int m_interval = 100;
    int m_threshold = 63;
    int m_protocol = 0;
    int m_coreCount = 2;
    int m_maxCores = 1;
    bool m_probe = false;
    bool m_suppressConnectToast = false;
    QHostAddress m_addr;
    QByteArray m_challenge;
    bool m_gotChallenge = false;
    bool m_waiting = false;
    int m_challengeOnly = 0;
    LangManager *m_lang = nullptr;
};

#endif
