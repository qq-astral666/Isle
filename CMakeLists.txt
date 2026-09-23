cmake_minimum_required(VERSION 3.21)

project(Isle
    VERSION 1.0.1
    DESCRIPTION "Dynamic Island for the MacBook notch"
    LANGUAGES CXX)

if(APPLE)
    enable_language(OBJCXX)
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(ISLE_BUILD_TESTS "Build unit tests" ON)

find_package(Qt6 6.9 REQUIRED COMPONENTS Core Gui Quick)
qt_standard_project_setup(REQUIRES 6.9)

# --------------------------------------------------------------------------
# Core: timer + shelf logic, no UI -> unit-tested.
# --------------------------------------------------------------------------
qt_add_library(isle_core STATIC
    src/core/FocusTimer.h
    src/core/FocusTimer.cpp
    src/core/ShelfModel.h
    src/core/ShelfModel.cpp
)
target_include_directories(isle_core PUBLIC src/core)
target_link_libraries(isle_core PUBLIC Qt6::Core)

# --------------------------------------------------------------------------
# Application
# --------------------------------------------------------------------------
qt_add_executable(Isle MACOSX_BUNDLE
    src/main.cpp
    src/app/NotchController.h
    src/app/NotchController.cpp
    src/app/NowPlaying.h
    src/app/NowPlaying.cpp
    src/app/ImageStore.h
    src/app/ImageStore.cpp
    src/app/QmlTypes.h
    src/platform/Native.h
    src/platform/Media.h
)
target_include_directories(Isle PRIVATE src/app src/platform)
target_compile_definitions(Isle PRIVATE PROJECT_VERSION_STRING="${PROJECT_VERSION}")

if(APPLE)
    target_sources(Isle PRIVATE src/platform/Native_mac.mm src/platform/Media_mac.mm)
    set_source_files_properties(src/platform/Native_mac.mm src/platform/Media_mac.mm
        PROPERTIES COMPILE_OPTIONS "-fobjc-arc")
    target_link_libraries(Isle PRIVATE
        "-framework AppKit"
        "-framework ServiceManagement")
else()
    target_sources(Isle PRIVATE src/platform/Platform_stub.cpp)
endif()

set(ISLE_QML_FILES
    qml/Main.qml
    qml/Theme.qml
    qml/Icon.qml
    qml/NotchShape.qml
    qml/RoundedImage.qml
    qml/EqBars.qml
    qml/IconButton.qml
    qml/Toggle.qml
    qml/MediaCard.qml
    qml/TimerCard.qml
    qml/ShelfCard.qml
    qml/SettingsPanel.qml
)
foreach(qml_file IN LISTS ISLE_QML_FILES)
    get_filename_component(qml_name "${qml_file}" NAME)
    set_source_files_properties("${qml_file}" PROPERTIES QT_RESOURCE_ALIAS "${qml_name}")
endforeach()
set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
# qmlcachegen's ahead-of-time C++ for ShelfCard (native Drag with a mimeData
# object) doesn't compile with Qt 6.11; interpret this one file instead.
set_source_files_properties(qml/ShelfCard.qml PROPERTIES QT_QML_SKIP_CACHEGEN TRUE)

qt_add_qml_module(Isle
    URI Isle
    VERSION 1.0
    QML_FILES ${ISLE_QML_FILES}
)

target_link_libraries(Isle PRIVATE isle_core Qt6::Gui Qt6::Quick)

set_target_properties(Isle PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Info.plist.in"
    MACOSX_BUNDLE_GUI_IDENTIFIER "app.isle.Isle"
    MACOSX_BUNDLE_BUNDLE_NAME "Isle"
    MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}"
)

# resources/AppIcon.icns is generated from AppIcon.png by scripts/package.sh.
if(APPLE AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/resources/AppIcon.icns")
    set(app_icon "${CMAKE_CURRENT_SOURCE_DIR}/resources/AppIcon.icns")
    set_source_files_properties(${app_icon} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
    target_sources(Isle PRIVATE ${app_icon})
    set_target_properties(Isle PROPERTIES MACOSX_BUNDLE_ICON_FILE "AppIcon.icns")
endif()

# --------------------------------------------------------------------------
# Tests
# --------------------------------------------------------------------------
if(ISLE_BUILD_TESTS)
    enable_testing()
    find_package(Qt6 REQUIRED COMPONENTS Test)
    qt_add_executable(tst_core tests/tst_core.cpp)
    target_link_libraries(tst_core PRIVATE isle_core Qt6::Test)
    add_test(NAME core COMMAND tst_core)
endif()
