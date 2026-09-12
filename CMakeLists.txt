cmake_minimum_required(VERSION 3.21)

project(CS2JoinTool VERSION 4.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    Network
    Svg
    Widgets
    OpenGL
)

qt_standard_project_setup(REQUIRES 6.5)

set(PROJECT_SOURCES
    main.cpp
    src/serverquery.h
    src/serverquery.cpp
    src/servermanager.h
    src/servermanager.cpp
    src/appcontroller.h
    src/appcontroller.cpp
    src/mapcooldownmanager.h
    src/mapcooldownmanager.cpp
    src/mapsubscriptionmanager.h
    src/mapsubscriptionmanager.cpp
    src/workshopmanager.h
    src/workshopmanager.cpp
    src/ubservermanager.h
    src/ubservermanager.cpp
    src/baservertime.h
    src/baservertime.cpp
    src/playerquery.h
    src/playerquery.cpp
    src/roundedcornerrenderer.h
    src/roundedcornerrenderer.cpp
    resources.qrc
    app.rc
)

qt_add_executable(CS2JoinTool
    ${PROJECT_SOURCES}
)

target_link_libraries(CS2JoinTool PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
    Qt6::Svg
    Qt6::Widgets
    Qt6::OpenGL
)

if(WIN32)
    target_link_libraries(CS2JoinTool PRIVATE ws2_32)
    set_target_properties(CS2JoinTool PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
endif()

include(GNUInstallDirs)
install(TARGETS CS2JoinTool
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
