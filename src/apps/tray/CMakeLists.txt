set(TRAY_SOURCES
    main.cpp
    TrayManager.h
    TrayManager.cpp
)
if(WIN32)
    list(APPEND TRAY_SOURCES app.rc)
endif()

add_executable(carbon-tray ${TRAY_SOURCES})

set_target_properties(carbon-tray PROPERTIES WIN32_EXECUTABLE TRUE)

target_include_directories(carbon-tray PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(carbon-tray PRIVATE
    carbon-engine-system
    carbon-engine-logging
    Qt6::Core
    Qt6::Widgets
)

if(WIN32)
    add_custom_command(TARGET carbon-tray POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/app.ico"
            $<TARGET_FILE_DIR:carbon-tray>/app.ico
    )
endif()

