#include "wheelExporter.h"

#include <QDir>
#include <QFile>
#include <QSettings>
#include <QStandardPaths>
#include <QStringList>
#include <QDebug>

#ifdef Q_OS_WIN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <shellapi.h>
#endif

void WheelExporter::openFolder(const QString &path)
{
    QString searchPath = path;

    if (path.contains("csgo/cfg") || path.contains("csgo\\cfg")) {
        QSettings reg("HKEY_CURRENT_USER\\Software\\Valve\\Steam", QSettings::NativeFormat);
        QString steamPath = reg.value("SteamPath").toString();
        if (!steamPath.isEmpty()) {
            steamPath.replace("/", "\\");
            QStringList candidates = {
                steamPath + "\\steamapps\\common\\Counter-Strike Global Offensive\\game\\csgo\\cfg",
                "E:\\SteamLibrary\\steamapps\\common\\Counter-Strike Global Offensive\\game\\csgo\\cfg",
                "D:\\SteamLibrary\\steamapps\\common\\Counter-Strike Global Offensive\\game\\csgo\\cfg",
                "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Counter-Strike Global Offensive\\game\\csgo\\cfg"
            };
            for (auto &cand : candidates) {
                if (QDir(cand).exists()) {
                    searchPath = cand;
                    break;
                }
            }
        }
    }
    std::wstring wpath = searchPath.toStdWString();
    ShellExecuteW(NULL, L"open", wpath.c_str(), NULL, NULL, SW_SHOWNORMAL);
}

void WheelExporter::exportFiles(const QString &cfg1, const QString &cfg2, const QString &cfg3,
                                const QString &autoexec, const QString &txt)
{
    QString base = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation) + "/轮盘配置";
    if (!QDir().mkpath(base + "/cfg/exgtools") || !QDir().mkpath(base + "/resource")) {
        qWarning() << "[WheelExporter] mkpath failed:" << base;
        return;
    }
    auto writeFile = [](const QString &path, const QString &content) {
        QFile f(path);
        if (f.open(QIODevice::WriteOnly | QIODevice::Text)) {
            f.write(content.toUtf8());
            f.close();
        }
    };
    writeFile(base + "/cfg/exgtools/servercommand.cfg", cfg1);
    writeFile(base + "/cfg/exgtools/servercommand2.cfg", cfg2);
    writeFile(base + "/cfg/exgtools/servercommand3.cfg", cfg3);

    QString text1 = "//一号轮盘显示自定义文字\n"
                    "cl_radial_radio_tab_0_text_1 #SFUI_ze_lunpan1_1\n"
                    "cl_radial_radio_tab_0_text_2 #SFUI_ze_lunpan1_2\n"
                    "cl_radial_radio_tab_0_text_3 #SFUI_ze_lunpan1_3\n"
                    "cl_radial_radio_tab_0_text_4 #SFUI_ze_lunpan1_4\n"
                    "cl_radial_radio_tab_0_text_5 #SFUI_ze_lunpan1_5\n"
                    "cl_radial_radio_tab_0_text_6 #SFUI_ze_lunpan1_6\n"
                    "cl_radial_radio_tab_0_text_7 #SFUI_ze_lunpan1_7\n"
                    "cl_radial_radio_tab_0_text_8 #SFUI_ze_lunpan1_8\n";
    QString text2 = "//二号轮盘显示自定义文字\n"
                    "cl_radial_radio_tab_1_text_1 #SFUI_ze_lunpan2_1\n"
                    "cl_radial_radio_tab_1_text_2 #SFUI_ze_lunpan2_2\n"
                    "cl_radial_radio_tab_1_text_3 #SFUI_ze_lunpan2_3\n"
                    "cl_radial_radio_tab_1_text_4 #SFUI_ze_lunpan2_4\n"
                    "cl_radial_radio_tab_1_text_5 #SFUI_ze_lunpan2_5\n"
                    "cl_radial_radio_tab_1_text_6 #SFUI_ze_lunpan2_6\n"
                    "cl_radial_radio_tab_1_text_7 #SFUI_ze_lunpan2_7\n"
                    "cl_radial_radio_tab_1_text_8 #SFUI_ze_lunpan2_8\n";
    QString text3 = "//三号轮盘显示自定义文字\n"
                    "cl_radial_radio_tab_2_text_1 #SFUI_ze_lunpan3_1\n"
                    "cl_radial_radio_tab_2_text_2 #SFUI_ze_lunpan3_2\n"
                    "cl_radial_radio_tab_2_text_3 #SFUI_ze_lunpan3_3\n"
                    "cl_radial_radio_tab_2_text_4 #SFUI_ze_lunpan3_4\n"
                    "cl_radial_radio_tab_2_text_5 #SFUI_ze_lunpan3_5\n"
                    "cl_radial_radio_tab_2_text_6 #SFUI_ze_lunpan3_6\n"
                    "cl_radial_radio_tab_2_text_7 #SFUI_ze_lunpan3_7\n"
                    "cl_radial_radio_tab_2_text_8 #SFUI_ze_lunpan3_8\n";
    writeFile(base + "/cfg/exgtools/text.cfg", text1);
    writeFile(base + "/cfg/exgtools/text2.cfg", text2);
    writeFile(base + "/cfg/exgtools/text3.cfg", text3);
    writeFile(base + "/cfg/autoexec.cfg", autoexec);
    writeFile(base + "/resource/platform_schinese.txt", txt);
    qInfo() << "[WheelExporter] exported to" << base;

    std::wstring wbase = base.toStdWString();
    ShellExecuteW(NULL, L"open", wbase.c_str(), NULL, NULL, SW_SHOWNORMAL);
}
