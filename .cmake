# HuskarUI CMake 配置文件
# 此文件由 HuskarUI 库自动生成，用于在 CMake 项目中查找和使用 HuskarUI 库

@PACKAGE_INIT@

# 设置并检查库的包含目录
set_and_check(HuskarUI_INCLUDE_DIR "@PACKAGE_INCLUDE_INSTALL_DIR@")

# 设置并检查库的库目录
set_and_check(HuskarUI_LIBRARY_DIR "@PACKAGE_LIB_INSTALL_DIR@")

# 设置并检查 QML 导入目录
set_and_check(HuskarUI_QML_IMPORT_PATH "@PACKAGE_QML_INSTALL_DIR@")

# 导入目标文件
include("${CMAKE_CURRENT_LIST_DIR}/HuskarUITargets.cmake")

# 检查必要的依赖
include(CMakeFindDependencyMacro)
find_dependency(Qt6 REQUIRED COMPONENTS Core Quick QuickTemplates2)

# 设置QML引擎的导入路径

function(hus_get_dir_sources)
    set(oneValueArgs OUTPUT)
    set(multiValueArgs FILTER)
    cmake_parse_arguments(PARAM "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    file(GLOB_RECURSE PATHS ${PARAM_FILTER})
    set(TEMP_OUTPUT "")
    foreach (filepath ${PATHS})
        string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/" "" filename ${filepath})
        list(APPEND TEMP_OUTPUT ${filename})
    endforeach (filepath)
    set(${PARAM_OUTPUT} ${TEMP_OUTPUT} PARENT_SCOPE)
endfunction()



function(hus_add_win_rc _target)
    if(NOT WIN32)
        return()
    endif()

    set(options)
    set(oneValueArgs COMMENTS NAME VERSION COMPANY DESCRIPTION COPYRIGHT TRADEMARK OUTPUT_FILE)
    set(multiValueArgs ICONS)
    cmake_parse_arguments(PARAM "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(_comments ${PARAM_COMMENTS})
    set(_name ${PARAM_NAME})
    set(_version ${PARAM_VERSION})
    set(_company ${PARAM_COMPANY})
    set(_desc ${PARAM_DESCRIPTION})
    set(_copyright ${PARAM_COPYRIGHT})
    set(_trademark ${PARAM_TRADEMARK})
    set(_out_file ${PARAM_OUTPUT_FILE})


    string(REPLACE "." ";" _version_list ${_version})
    list(LENGTH _version_list _version_count)
    list(PREPEND _version_list 0)
    foreach(_i RANGE 1 4)
        if(_i LESS_EQUAL _version_count)
            list(GET _version_list ${_i} _item)
        else()
            set(_item 0)
        endif()

        set(_ver_${_i} ${_item})
    endforeach()
    set(RC_VERSION ${_ver_1},${_ver_2},${_ver_3},${_ver_4})
    set(RC_VERSION_STRING ${_ver_1}.${_ver_2}.${_ver_3}.${_ver_4})


    GET_FILENAME_COMPONENT(_file_ext ${_name} EXT)
    if (_file_ext STREQUAL ".exe")
        set(RC_FILE_TYPE VFT_APP)
    elseif (_file_ext STREQUAL ".dll")
        set(RC_FILE_TYPE VFT_DLL)
    elseif (_file_ext STREQUAL ".lib")
        set(RC_FILE_TYPE VFT_STATIC_LIB)
    else()
        set(RC_FILE_TYPE VFT_UNKNOWN)
    endif()

    set(RC_COMMENTS ${_comments})
    set(RC_COMPANY ${_company})
    set(RC_DESCRIPTION ${_desc})
    set(RC_COPYRIGHT ${_copyright})
    set(RC_TRADEMARK ${_trademark})
    set(RC_FILENAME ${_name})
    set(RC_PROJECT_NAME ${_target})

    set(_icons)

    if(PARAM_ICONS)
        set(_index 1)

        foreach(_icon IN LISTS PARAM_ICONS)
            get_filename_component(_icon_path ${_icon} ABSOLUTE)
            string(APPEND _icons "IDI_ICON${_index}    ICON    \"${_icon_path}\"\n")
            math(EXPR _index "${_index} +1")
        endforeach()
    endif()

    set(RC_ICONS ${_icons})

    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/WinResource.rc.in" ${_out_file})

    foreach(_icon IN LISTS PARAM_ICONS)
        if(${_icon} IS_NEWER_THAN ${_out_file})
            file(TOUCH_NOCREATE ${_out_file})
            break()
        endif()
    endforeach()
endfunction()

if(DEFINED QML_IMPORT_PATH)
    list(FIND QML_IMPORT_PATH "${HuskarUI_QML_IMPORT_PATH}" _found_index)
    if(_found_index EQUAL -1)
        list(APPEND QML_IMPORT_PATH "${HuskarUI_QML_IMPORT_PATH}")
        set(QML_IMPORT_PATH "${QML_IMPORT_PATH}" CACHE PATH "QML import path" FORCE)
    endif()#include <windows.h>

@RC_ICONS@

VS_VERSION_INFO VERSIONINFO
FILEVERSION     @RC_VERSION@
PRODUCTVERSION  @RC_VERSION@
FILEFLAGSMASK   0x3fL
#ifdef _DEBUG
FILEFLAGS       VS_FF_DEBUG
#else
FILEFLAGS       0x0L
#endif
FILEOS          VOS_NT_WINDOWS32
FILETYPE        @RC_FILE_TYPE@
FILESUBTYPE     VFT2_UNKNOWN
BEGIN
    BLOCK "StringFileInfo"
    BEGIN
        BLOCK "080404b0"
        BEGIN
            VALUE "Comments",         "@RC_COMMENTS@"
            VALUE "CompanyName",      "@RC_COMPANY@"
            VALUE "FileDescription",  "@RC_DESCRIPTION@"
            VALUE "FileVersion",      "@RC_VERSION_STRING@"
            VALUE "InternalName",     "@RC_PROJECT_NAME@"
            VALUE "LegalCopyright",   "@RC_COPYRIGHT@"
            VALUE "LegalTrademarks",  "@RC_TRADEMARK@"
            VALUE "OriginalFilename", "@RC_FILENAME@"
            VALUE "ProductName",      "@RC_PROJECT_NAME@"
            VALUE "ProductVersion",   "@RC_VERSION_STRING@"
        END
    END
    BLOCK "VarFileInfo"
    BEGIN
        VALUE "Translation", 0x804, 1200
    END
END

else()
    set(QML_IMPORT_PATH "${HuskarUI_QML_IMPORT_PATH}" CACHE PATH "QML import path")
endif()
