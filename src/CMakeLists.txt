# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(flutter_pulseaudio_library VERSION 0.0.1 LANGUAGES C)

add_library(flutter_pulseaudio SHARED
  "flutter_pulseaudio.c"
)

set_target_properties(flutter_pulseaudio PROPERTIES
  PUBLIC_HEADER flutter_pulseaudio.h
  OUTPUT_NAME "flutter_pulseaudio"
)

target_compile_definitions(flutter_pulseaudio PUBLIC DART_SHARED_LIB)
