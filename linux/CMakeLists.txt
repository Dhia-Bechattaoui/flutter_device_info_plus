cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "flutter_device_info_plus")
project(${PROJECT_NAME} LANGUAGES CXX)
# This is the CMake configuration for the plugin. It is included by
# Flutter's generated plugin build rules.
set(PLUGIN_NAME "flutter_device_info_plus_plugin")
# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "flutter_device_info_plus_plugin.cpp"
  "include/flutter_device_info_plus/flutter_device_info_plus_plugin.h"
)
# Plugin header files (if any)
add_library(${PLUGIN_NAME} SHARED
  ${PLUGIN_SOURCES}
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
  target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
  target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)


# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(flutter_device_info_plus_bundled_libraries
  ""
  PARENT_SCOPE
)
