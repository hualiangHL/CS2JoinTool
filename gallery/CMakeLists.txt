cmake_minimum_required(VERSION 3.16)

project(Gallery VERSION 4.4.5 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../bin/${CMAKE_BUILD_TYPE})
find_package(Qt6 6.5 COMPONENTS Quick Network Widgets REQUIRED)

qt_standard_project_setup(REQUIRES 6.5)


include(${CMAKE_CURRENT_LIST_DIR}/../.cmake/HuskarUIHelper.cmake)

set(GALLERY_RC_FILE "")
if(WIN32)
    set(GALLERY_RC_FILE ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_Resource.rc)
    hus_add_win_rc(${PROJECT_NAME}
        COMMENTS "HuskarUI Gallery"
        NAME "${PROJECT_NAME}.exe"
        COMPANY "HuskarUI"
        DESCRIPTION ""
        VERSION "${PROJECT_VERSION}"
        COPYRIGHT "Copyright (C) 2026 mengps. All rights reserved."
        ICONS ../resources/v2/huskarui_new_square.ico
        OUTPUT_FILE "${GALLERY_RC_FILE}"
    )
endif()

qt_add_executable(${PROJECT_NAME})

if(QT_KNOWN_POLICY_QTP0004)
    qt_policy(SET QTP0004 NEW)
endif()

qt_add_qml_module(${PROJECT_NAME}
    URI Gallery
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
    RESOURCE_PREFIX "/"
    QML_FILES
        qml/Examples/General/ExpWindow.qml
        qml/Examples/General/ExpButton.qml
        qml/Examples/General/ExpIconButton.qml
        qml/Examples/General/ExpCaptionButton.qml
        qml/Examples/General/ExpIconText.qml
        qml/Examples/General/ExpCopyableText.qml
        qml/Examples/General/ExpRectangle.qml
        qml/Examples/General/ExpPopup.qml
        qml/Examples/General/ExpText.qml
        qml/Examples/General/ExpButtonBlock.qml
        qml/Examples/General/ExpCaptionBar.qml
        qml/Examples/General/ExpMoveMouseArea.qml
        qml/Examples/General/ExpResizeMouseArea.qml
        qml/Examples/General/ExpRadius.qml
        qml/Examples/General/ExpLabel.qml
        qml/Examples/General/ExpFrame.qml
        qml/Examples/General/ExpPage.qml
        qml/Examples/General/ExpBorder.qml
        qml/Examples/DataEntry/ExpSwitch.qml
        qml/Examples/DataEntry/ExpSlider.qml
        qml/Examples/DataEntry/ExpSelect.qml
        qml/Examples/DataEntry/ExpInput.qml
        qml/Examples/DataEntry/ExpOTPInput.qml
        qml/Examples/DataEntry/ExpRate.qml
        qml/Examples/DataEntry/ExpRadio.qml
        qml/Examples/DataEntry/ExpRadioBlock.qml
        qml/Examples/DataEntry/ExpCheckBox.qml
        qml/Examples/DataEntry/ExpAutoComplete.qml
        qml/Examples/DataEntry/ExpInputInteger.qml
        qml/Examples/DataEntry/ExpInputNumber.qml
        qml/Examples/DataEntry/ExpMultiSelect.qml
        qml/Examples/DataEntry/ExpMultiCheckBox.qml
        qml/Examples/DataEntry/ExpDateTimePicker.qml
        qml/Examples/DataEntry/ExpDateTimePickerPanel.qml
        qml/Examples/DataEntry/ExpTextArea.qml
        qml/Examples/DataEntry/ExpColorPickerPanel.qml
        qml/Examples/DataEntry/ExpColorPicker.qml
        qml/Examples/DataEntry/ExpTransfer.qml
        qml/Examples/DataDisplay/ExpToolTip.qml
        qml/Examples/DataDisplay/ExpTourFocus.qml
        qml/Examples/DataDisplay/ExpTourStep.qml
        qml/Examples/DataDisplay/ExpTabView.qml
        qml/Examples/DataDisplay/ExpCollapse.qml
        qml/Examples/DataDisplay/ExpAvatar.qml
        qml/Examples/DataDisplay/ExpCard.qml
        qml/Examples/DataDisplay/ExpTimeline.qml
        qml/Examples/DataDisplay/ExpTag.qml
        qml/Examples/DataDisplay/ExpTableView.qml
        qml/Examples/DataDisplay/ExpBadge.qml
        qml/Examples/DataDisplay/ExpCarousel.qml
        qml/Examples/DataDisplay/ExpImage.qml
        qml/Examples/DataDisplay/ExpAnimatedImage.qml
        qml/Examples/DataDisplay/ExpImagePreview.qml
        qml/Examples/DataDisplay/ExpImagePreviewPanel.qml
        qml/Examples/DataDisplay/ExpEmpty.qml
        qml/Examples/DataDisplay/ExpQrCode.qml
        qml/Examples/DataDisplay/ExpCheckerBoard.qml
        qml/Examples/DataDisplay/ExpTreeView.qml
        qml/Examples/DataDisplay/ExpSegmented.qml
        qml/Examples/Navigation/ExpMenu.qml
        qml/Examples/Navigation/ExpContextMenu.qml
        qml/Examples/Navigation/ExpScrollBar.qml
        qml/Examples/Navigation/ExpPagination.qml
        qml/Examples/Navigation/ExpBreadcrumb.qml
        qml/Examples/Layout/ExpDivider.qml
        qml/Examples/Layout/ExpSpace.qml
        qml/Examples/Layout/ExpGroupBox.qml
        qml/Examples/Layout/ExpSplitView.qml
        qml/Examples/Effect/ExpAcrylic.qml
        qml/Examples/Effect/ExpLiquidGlass.qml
        qml/Examples/Effect/ExpSwitchEffect.qml
        qml/Examples/Effect/ExpShadow.qml
        qml/Examples/Feedback/ExpWatermark.qml
        qml/Examples/Feedback/ExpDrawer.qml
        qml/Examples/Feedback/ExpMessage.qml
        qml/Examples/Feedback/ExpProgress.qml
        qml/Examples/Feedback/ExpNotification.qml
        qml/Examples/Feedback/ExpPopconfirm.qml
        qml/Examples/Feedback/ExpPopover.qml
        qml/Examples/Feedback/ExpModal.qml
        qml/Examples/Feedback/ExpSpin.qml
        qml/Examples/Utils/ExpAsyncHasher.qml
        qml/Examples/Utils/ExpRouter.qml
        qml/Examples/Server/ExpServerList.qml
        qml/Examples/Server/ExpServerListZed.qml
        qml/Examples/Server/ExpServerListUb.qml
        qml/Examples/Server/ExpServerListFys.qml
        qml/Examples/Server/ExpServerListUpkk.qml
        qml/Examples/Server/ExpServerListInternational.qml
        qml/Examples/Server/ExpServerListStar.qml
        qml/Examples/Server/ExpServerListMapRun.qml
        qml/Examples/Server/CooldownPage.qml
        qml/Examples/Server/SubscriptionPage.qml
        qml/Examples/Server/BrowserPage.qml
qml/Examples/Server/WorkshopPage.qml
        qml/Examples/Server/CommandsListPage.qml
        qml/Examples/Server/RadialWheelPage.qml
        qml/Examples/Server/SqueezePanel.qml
        qml/Examples/Server/ServerPlayersPanel.qml
        qml/Examples/Server/ServerCard.qml
        qml/Examples/Server/ServerContextMenu.qml
        qml/Examples/Theme/ExpTheme.qml
        qml/Examples/Functions/ExpApi.qml
        qml/Controls/CodeBox.qml
        qml/Controls/Description.qml
        qml/Controls/DocDescription.qml
        qml/Controls/CodeRunner.qml
        qml/Controls/ThemeToken.qml
        qml/Controls/UpdateDesc.qml
        qml/Controls/CommitHistory.qml
        qml/Controls/GradientFlowEffect.qml
        qml/Home/HomeMainPage.qml
        qml/Home/HomePage.qml
        qml/Home/AboutPage.qml
        qml/Home/SettingsPage.qml
        qml/Home/CreatorPage.qml
        qml/Home/OverviewPage.qml
        qml/Global.qml
        qml/Gallery.qml
    SOURCES
        $<$<BOOL:${WIN32}>:${GALLERY_RC_FILE}>
        cpp/customtheme.h cpp/customtheme.cpp        cpp/themeswitchitem.h cpp/themeswitchitem.cpp
        cpp/datagenerator.h cpp/datagenerator.cpp
        cpp/serverqueryengine.h cpp/serverqueryengine.cpp
        cpp/zedserverqueryengine.h cpp/zedserverqueryengine.cpp
        cpp/ubserverqueryengine.h cpp/ubserverqueryengine.cpp
        cpp/fysserverqueryengine.h cpp/fysserverqueryengine.cpp
        cpp/upkkserverqueryengine.h cpp/upkkserverqueryengine.cpp
        cpp/internationalserverqueryengine.h cpp/internationalserverqueryengine.cpp
        cpp/starserverqueryengine.h cpp/starserverqueryengine.cpp
        cpp/maprunserverqueryengine.h cpp/maprunserverqueryengine.cpp
        cpp/squeezeengine.h cpp/squeezeengine.cpp
        cpp/playerqueryengine.h cpp/playerqueryengine.cpp
        cpp/maptranslator.h cpp/maptranslator.cpp
        cpp/ubservermanager.h cpp/ubservermanager.cpp
        cpp/workshoppreviewmanager.h cpp/workshoppreviewmanager.cpp
        cpp/onlinehistorymanager.h cpp/onlinehistorymanager.cpp
        cpp/mapcooldownmanager.h cpp/mapcooldownmanager.cpp
        cpp/baservertime.h cpp/baservertime.cpp
        cpp/backgroundfilemanager.h cpp/backgroundfilemanager.cpp
        cpp/appconfig.h cpp/appconfig.cpp
        cpp/joinhistorymanager.h cpp/joinhistorymanager.cpp
        cpp/updatechecker.h cpp/updatechecker.cpp
        cpp/langmanager.h cpp/langmanager.cpp
cpp/workshopmanager.h cpp/workshopmanager.cpp
        cpp/wheelExporter.h cpp/wheelExporter.cpp
        cpp/creator.h cpp/creator_p.h cpp/creator.cpp
        cpp/mapsubscriptionmanager.h cpp/mapsubscriptionmanager.cpp
        cpp/webview2browser.h cpp/webview2browser.cpp
        cpp/browsercontroller.h cpp/browsercontroller.cpp
        cpp/main.cpp
)

qt_add_resources(${PROJECT_NAME} "images"
    PREFIX "/Gallery"
    FILES
        images/huskarui_new_square.svg
        images/app_icon.png
        images/monitor.svg
        images/switch_effect1.jpg
        images/switch_effect2.jpg
        images/wheel_help0.jpg
        images/wheel_help1.jpg
        images/wheel_help2.jpg
        images/wheel_help3.jpg
        images/meme_squeeze.png
)

qt_add_shaders(${PROJECT_NAME} "shaders"
    PREFIX "/Gallery"
    FILES
        shaders/effect1.vert
        shaders/effect1.frag
        shaders/effect2.vert
        shaders/effect2.frag
)

set_target_properties(${PROJECT_NAME} PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER huskarui.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)


if(ANDROID)
    include(FetchContent)
    FetchContent_Declare(
      android_openssl
      DOWNLOAD_EXTRACT_TIMESTAMP true
      URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip

    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
    add_android_openssl_libraries(${PROJECT_NAME})
endif()

target_include_directories(${PROJECT_NAME} PRIVATE
    cpp
    ${CMAKE_SOURCE_DIR}/3rdparty/webview2/include
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Quick
    Qt6::Widgets
    HuskarUIBasic
    $<$<BOOL:${WIN32}>:winmm>
    $<$<BOOL:${WIN32}>:ole32>
    $<$<BOOL:${BUILD_HUSKARUI_STATIC_LIBRARY}>:HuskarUIImplPlugin>
    $<$<BOOL:${BUILD_HUSKARUI_STATIC_LIBRARY}>:HuskarUIBasicPlugin>
)


if(NOT HUSKARUI_PLUGIN_OUTPUT_DIRECTORY)
    set(QML_IMPORT_PATH ${CMAKE_BINARY_DIR}/HuskarUI/qml CACHE STRING "" FORCE)
else()
    set(QML_IMPORT_PATH ${HUSKARUI_PLUGIN_OUTPUT_DIRECTORY}/HuskarUI/qml CACHE STRING "" FORCE)
endif()
target_compile_definitions(${PROJECT_NAME} PRIVATE HUSKARUI_IMPORT_PATH="${QML_IMPORT_PATH}")




target_compile_definitions(${PROJECT_NAME} PRIVATE GALLERY_VERSION="${PROJECT_VERSION}")

if(BUILD_HUSKARUI_STATIC_LIBRARY)
    target_compile_definitions(${PROJECT_NAME} PRIVATE BUILD_HUSKARUI_STATIC_LIBRARY)
endif()


if(CMAKE_BUILD_TYPE MATCHES "Release")
    if(APPLE)
        find_program(QT_DEPLOY_QT NAMES macdeployqt)
        set(QT_DEPLOY_ARGS
            ${CMAKE_CURRENT_SOURCE_DIR}/../package/${PROJECT_NAME}.app
            -qmldir=${CMAKE_CURRENT_SOURCE_DIR}
        )
        add_custom_target(Script-DeployRelease
                COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_CURRENT_SOURCE_DIR}/../package
                COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.app
                    ${CMAKE_CURRENT_SOURCE_DIR}/../package/${PROJECT_NAME}.app
                COMMAND ${QT_DEPLOY_QT} ${QT_DEPLOY_ARGS}
                COMMENT "MacOs Deploying Qt Dependencies After Build........."
                SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
        add_dependencies(Script-DeployRelease ${PROJECT_NAME})
    endif()
    if(WIN32)
        find_program(QT_DEPLOY_QT NAMES windeployqt)
        set(QT_DEPLOY_ARGS
            ${CMAKE_CURRENT_SOURCE_DIR}/../package/${PROJECT_NAME}.exe
            --qmldir=${CMAKE_CURRENT_SOURCE_DIR}
            --plugindir=${CMAKE_CURRENT_SOURCE_DIR}/../package/plugins
            --no-opengl-sw
            --no-widgets
            --no-quickcontrols2windowsstyleimpl
            --no-quickcontrols2fusion
            --no-quickcontrols2fusionstyleimpl
            --no-quickcontrols2material
            --no-quickcontrols2materialstyleimpl
            --no-quickcontrols2universal
            --no-quickcontrols2universalstyleimpl
            --no-quickcontrols2imagine
            --no-quickcontrols2imaginestyleimpl
            --no-translations
            --compiler-runtime
        )
        add_custom_target(Script-DeployRelease
                COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_CURRENT_SOURCE_DIR}/../package
                COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_RUNTIME_OUTPUT_DIRECTORY} ${CMAKE_CURRENT_SOURCE_DIR}/../package
                COMMAND ${CMAKE_COMMAND} -E rm -f "${CMAKE_CURRENT_SOURCE_DIR}/../package/${PROJECT_NAME}.qmltypes"
                COMMAND ${CMAKE_COMMAND} -E rm -f "${CMAKE_CURRENT_SOURCE_DIR}/../package/${PROJECT_NAME}_qml_module_dir_map.qrc"
                COMMAND ${CMAKE_COMMAND} -E rm -f "${CMAKE_CURRENT_SOURCE_DIR}/../package/qmldir"
                COMMAND ${CMAKE_COMMAND} -E copy ${Qt6_DIR}/../../../bin/HuskarUIImpl.dll ${CMAKE_CURRENT_SOURCE_DIR}/../package
                COMMAND ${CMAKE_COMMAND} -E copy ${Qt6_DIR}/../../../bin/HuskarUIBasic.dll ${CMAKE_CURRENT_SOURCE_DIR}/../package
                COMMAND ${QT_DEPLOY_QT} ${QT_DEPLOY_ARGS}
                COMMENT "Windows Deploying Qt Dependencies After Build........."
                SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
        add_dependencies(Script-DeployRelease ${PROJECT_NAME})
    endif()
endif()
