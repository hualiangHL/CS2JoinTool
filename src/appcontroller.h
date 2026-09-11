#ifndef APPCONTROLLER_H
#define APPCONTROLLER_H

#include <QObject>
#include <QTimer>
#include <QSettings>
#include <QSystemTrayIcon>
#include <QQuickWindow>
#include <QLocalServer>
#include <QLocalSocket>
#include "serverquery.h"
#include "roundedcornerrenderer.h"

#ifdef Q_OS_WIN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

class AppController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString serverIp READ serverIp WRITE setServerIp NOTIFY serverIpChanged)
    Q_PROPERTY(int serverPort READ serverPort WRITE setServerPort NOTIFY serverPortChanged)
    Q_PROPERTY(QString serverPassword READ serverPassword WRITE setServerPassword NOTIFY serverPasswordChanged)
    Q_PROPERTY(double interval READ interval WRITE setInterval NOTIFY intervalChanged)
    Q_PROPERTY(bool autoJoining READ isAutoJoining NOTIFY autoJoiningChanged)
    Q_PROPERTY(bool connected READ connected WRITE setConnected NOTIFY connectedChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(int retryCount READ retryCount NOTIFY retryCountChanged)
    Q_PROPERTY(int maxRetryCount READ maxRetryCount WRITE setMaxRetryCount NOTIFY maxRetryCountChanged)
    Q_PROPERTY(bool darkTheme READ darkTheme WRITE setDarkTheme NOTIFY darkThemeChanged)
    Q_PROPERTY(bool alwaysOnTop READ alwaysOnTop WRITE setAlwaysOnTop NOTIFY alwaysOnTopChanged)
    Q_PROPERTY(bool autoRetryJoin READ autoRetryJoin WRITE setAutoRetryJoin NOTIFY autoRetryJoinChanged)
    Q_PROPERTY(int currentPlayers READ currentPlayers NOTIFY currentPlayersChanged)
    Q_PROPERTY(int maxPlayers READ maxPlayers NOTIFY maxPlayersChanged)
    Q_PROPERTY(QString currentMap READ currentMap NOTIFY currentMapChanged)
    Q_PROPERTY(QString currentServerName READ currentServerName NOTIFY currentServerNameChanged)
    Q_PROPERTY(int serverStatus READ serverStatus NOTIFY serverStatusChanged)
    Q_PROPERTY(QString logText READ logText NOTIFY logTextChanged)
    Q_PROPERTY(QString joinStatus READ joinStatus NOTIFY joinStatusChanged)
    Q_PROPERTY(int joinPhase READ joinPhase NOTIFY joinPhaseChanged)
    Q_PROPERTY(int connectProtocol READ connectProtocol WRITE setConnectProtocol NOTIFY connectProtocolChanged)
    Q_PROPERTY(int defaultConnectProtocol READ defaultConnectProtocol WRITE setDefaultConnectProtocol NOTIFY defaultConnectProtocolChanged)
    Q_PROPERTY(int joinThreshold READ joinThreshold WRITE setJoinThreshold NOTIFY joinThresholdChanged)
    Q_PROPERTY(int bgMode READ bgMode WRITE setBgMode NOTIFY bgModeChanged)
    Q_PROPERTY(bool transparentWindow READ transparentWindow WRITE setTransparentWindow NOTIFY transparentWindowChanged)
    Q_PROPERTY(bool proMode READ proMode WRITE setProMode NOTIFY proModeChanged)
    Q_PROPERTY(bool floatWindowEnabled READ floatWindowEnabled WRITE setFloatWindowEnabled NOTIFY floatWindowEnabledChanged)
    Q_PROPERTY(int closeBehavior READ closeBehavior WRITE setCloseBehavior NOTIFY closeBehaviorChanged)
    Q_PROPERTY(bool startMinimizedToTray READ startMinimizedToTray WRITE setStartMinimizedToTray NOTIFY startMinimizedToTrayChanged)
    Q_PROPERTY(bool difficultyTierMode READ difficultyTierMode WRITE setDifficultyTierMode NOTIFY difficultyTierModeChanged)
    Q_PROPERTY(bool joinNotificationEnabled READ joinNotificationEnabled WRITE setJoinNotificationEnabled NOTIFY joinNotificationEnabledChanged)
    Q_PROPERTY(QString configFolderPath READ configFolderPath NOTIFY configFolderPathChanged)
    Q_PROPERTY(bool debugPlayerList READ debugPlayerList WRITE setDebugPlayerList NOTIFY debugPlayerListChanged)
    Q_PROPERTY(int webMenuCommunity READ webMenuCommunity WRITE setWebMenuCommunity NOTIFY webMenuCommunityChanged)

public:
    explicit AppController(QObject *parent = nullptr);
    ~AppController();

    QString serverIp() const { return m_serverIp; }
    void setServerIp(const QString &ip);
    int serverPort() const { return m_serverPort; }
    void setServerPort(int port);
    QString serverPassword() const { return m_serverPassword; }
    void setServerPassword(const QString &pwd);
    double interval() const { return m_interval; }
    void setInterval(double ms);
    bool isAutoJoining() const { return m_autoJoining; }
    bool connected() const { return m_connected; }
    void setConnected(bool c);
    QString statusText() const { return m_statusText; }
    int retryCount() const { return m_retryCount; }
    int maxRetryCount() const { return m_maxRetryCount; }
    void setMaxRetryCount(int max);
    bool darkTheme() const { return m_darkTheme; }
    void setDarkTheme(bool dark);
    bool alwaysOnTop() const { return m_alwaysOnTop; }
    void setAlwaysOnTop(bool top);
    bool autoRetryJoin() const { return m_autoRetryJoin; }
    void setAutoRetryJoin(bool retry);
    int currentPlayers() const { return m_currentPlayers; }
    int maxPlayers() const { return m_maxPlayers; }
    QString currentMap() const { return m_currentMap; }
    QString currentServerName() const { return m_currentServerName; }
    int serverStatus() const { return m_serverStatus; }
    QString logText() const { return m_logText; }
    QString joinStatus() const { return m_joinStatus; }
    int joinPhase() const { return m_joinPhase; }
    int connectProtocol() const { return m_connectProtocol; }
    void setConnectProtocol(int proto);
    int defaultConnectProtocol() const { return m_defaultConnectProtocol; }
    void setDefaultConnectProtocol(int proto);
    int joinThreshold() const { return m_joinThreshold; }
    void setJoinThreshold(int threshold);
    int bgMode() const { return m_bgMode; }
    void setBgMode(int mode);
    bool transparentWindow() const { return m_transparentWindow; }
    void setTransparentWindow(bool t);
    bool proMode() const { return m_proMode; }
    void setProMode(bool p);
    bool floatWindowEnabled() const { return m_floatWindowEnabled; }
    void setFloatWindowEnabled(bool e);
    int closeBehavior() const { return m_closeBehavior; }
    void setCloseBehavior(int b);
    bool startMinimizedToTray() const { return m_startMinimizedToTray; }
    void setStartMinimizedToTray(bool e);
    bool difficultyTierMode() const { return m_difficultyTierMode; }
    void setDifficultyTierMode(bool v);
    bool joinNotificationEnabled() const { return m_joinNotificationEnabled; }
    void setJoinNotificationEnabled(bool v);
    QString configFolderPath() const;
    Q_INVOKABLE void openConfigFolder();
    bool debugPlayerList() const { return m_debugPlayerList; }
    void setDebugPlayerList(bool v);
    int webMenuCommunity() const { return m_webMenuCommunity; }
    void setWebMenuCommunity(int v);

    Q_INVOKABLE void queryServer();
    Q_INVOKABLE QString difficultyToTier(const QString &diff);
    Q_INVOKABLE void startAutoJoin();
    Q_INVOKABLE void stopAutoJoin();
    Q_INVOKABLE void joinNow();
    Q_INVOKABLE void cancelJoin();
    Q_INVOKABLE void clearLog();
    Q_INVOKABLE void saveSettings();
    Q_INVOKABLE void loadSettings();
    Q_INVOKABLE void openUrlDefaultBrowser(const QString &url);
    Q_INVOKABLE void tryClose();
    Q_INVOKABLE void minimizeToTray();
    Q_INVOKABLE void showMainWindow();
    Q_INVOKABLE void quitApp();
    Q_INVOKABLE void applyWindowMask(QQuickWindow *window, int radius);
    Q_INVOKABLE void applyDwmRoundedCorners(QQuickWindow *window);
    Q_INVOKABLE void setupRoundedCorners(QQuickWindow *window);
    void showToastNotification(const QString &title, const QString &message);
    static void notifyExistingInstance();

signals:
    void serverIpChanged(const QString &ip);
    void serverPortChanged(int port);
    void serverPasswordChanged(const QString &pwd);
    void intervalChanged(double ms);
    void autoJoiningChanged(bool joining);
    void connectedChanged(bool c);
    void statusTextChanged(const QString &text);
    void retryCountChanged(int count);
    void maxRetryCountChanged(int max);
    void darkThemeChanged(bool dark);
    void alwaysOnTopChanged(bool top);
    void autoRetryJoinChanged(bool retry);
    void currentPlayersChanged(int players);
    void maxPlayersChanged(int max);
    void toastRequested(const QString &title, const QString &message);
    void currentMapChanged(const QString &map);
    void currentServerNameChanged(const QString &name);
    void serverStatusChanged(int status);
    void logTextChanged(const QString &text);
    void closeDialogRequested();
    void joinSuccess();
    void joinFailed(const QString &reason);
    void joinStatusChanged(const QString &status);
    void joinPhaseChanged(int phase);
    void connectProtocolChanged(int proto);
    void defaultConnectProtocolChanged(int proto);
    void joinThresholdChanged(int threshold);
    void bgModeChanged(int mode);
    void transparentWindowChanged(bool t);
    void proModeChanged(bool p);
    void floatWindowEnabledChanged(bool e);
    void closeBehaviorChanged(int b);
    void startMinimizedToTrayChanged(bool e);
    void difficultyTierModeChanged(bool v);
    void joinNotificationEnabledChanged(bool v);
    void configFolderPathChanged();
    void debugPlayerListChanged(bool v);
    void webMenuCommunityChanged(int v);
    void activateRequested();

private slots:
    void onQueryFinished(const ServerInfo &info);
    void onQueryError(const QString &error);
    void onAutoJoinTick();

private:
    ServerQuery *m_query;
    QTimer *m_autoJoinTimer;
    QSettings *m_settings;
    QSystemTrayIcon *m_tray = nullptr;
    RoundedCornerRenderer *m_roundedRenderer = nullptr;
    QLocalServer *m_activateServer = nullptr;

    QString m_serverIp;
    int m_serverPort;
    QString m_serverPassword;
    double m_interval;
    bool m_autoJoining;
    bool m_connected;
    QString m_statusText;
    int m_retryCount;
    int m_maxRetryCount;
    bool m_darkTheme;
    bool m_alwaysOnTop;
    bool m_autoRetryJoin;
    int m_currentPlayers;
    int m_maxPlayers;
    QString m_currentMap;
    QString m_currentServerName;
    int m_serverStatus; 
    QString m_logText;

    
    QString m_joinStatus;
    int m_joinPhase;      
    int m_connectProtocol;
    int m_defaultConnectProtocol;
    int m_joinThreshold;
    int m_bgMode;  
    bool m_transparentWindow;
    bool m_proMode;
    bool m_floatWindowEnabled;
    int m_closeBehavior;
    bool m_startMinimizedToTray;
    bool m_difficultyTierMode;
    bool m_joinNotificationEnabled;
    bool m_debugPlayerList;
    int m_webMenuCommunity = 0;

    void appendLog(const QString &msg, bool isError = false);
    void setStatus(const QString &text);
    void setJoinStatus(const QString &text, int phase);
};

#endif

