cmake_minimum_required(VERSION 3.21)

project(RoundedClip LANGUAGES CXX)

find_package(Qt6 REQUIRED COMPONENTS Quick Qml)

qt_standard_project_setup()

qt_add_library(roundedclip SHARED)

qt_add_qml_module(roundedclip
    URI RoundedClip
    VERSION 1.0
    SOURCES
        roundedclip.h
        roundedclip.cpp
)

target_link_libraries(roundedclip
    PRIVATE
        Qt6::Quick
        Qt6::Qml
)
