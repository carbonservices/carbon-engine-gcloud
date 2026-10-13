# ─────────────────────────────────────────────────────────────
# Carbon Services - Carbon ESG & Carbon Engine Packaging Setup
# ─────────────────────────────────────────────────────────────

include(GNUInstallDirs)

# 1. Target Installation Rules
install(TARGETS carbon-engine-client
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    BUNDLE DESTINATION .
)

install(TARGETS carbon-engine
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    BUNDLE DESTINATION .
)

# 2. Asset & Shared Library Installation Rules
if(WIN32)
    # Windows dynamic dependencies & assets
    if(EXISTS "${pdfium_SOURCE_DIR}/bin/pdfium.dll")
        install(FILES "${pdfium_SOURCE_DIR}/bin/pdfium.dll"
            DESTINATION ${CMAKE_INSTALL_BINDIR}
        )
    endif()

    install(FILES "${CMAKE_SOURCE_DIR}/src/libs/common/templates/template.html"
        DESTINATION templates
    )
    install(FILES "${CMAKE_SOURCE_DIR}/src/apps/qml-client/logo.png"
        DESTINATION .
    )
    install(FILES "${CMAKE_SOURCE_DIR}/src/apps/server/app.ico"
        DESTINATION .
    )
else()
    # Linux dynamic dependencies & desktop integration
    if(EXISTS "${pdfium_SOURCE_DIR}/lib/libpdfium.so")
        install(FILES "${pdfium_SOURCE_DIR}/lib/libpdfium.so"
            DESTINATION ${CMAKE_INSTALL_LIBDIR}
        )
    endif()

    install(FILES "${CMAKE_SOURCE_DIR}/src/libs/common/templates/template.html"
        DESTINATION share/carbon-esg/templates
    )
    install(FILES "${CMAKE_CURRENT_LIST_DIR}/linux/carbon-esg.desktop"
        DESTINATION share/applications
    )
    install(FILES "${CMAKE_CURRENT_LIST_DIR}/linux/carbon-esg.png"
        DESTINATION share/icons/hicolor/256x256/apps
    )
endif()

if(EXISTS "${CMAKE_SOURCE_DIR}/eng.traineddata")
    install(FILES "${CMAKE_SOURCE_DIR}/eng.traineddata"
        DESTINATION share/tessdata
    )
endif()

# 3. CPack Configuration
set(CPACK_PACKAGE_NAME "CarbonESG")
set(CPACK_PACKAGE_VENDOR "Carbon Services")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Carbon ESG - Enterprise Statutory BRSR Reporting Application")
set(CPACK_PACKAGE_VERSION "${CARBON_ENGINE_VERSION}")
set(CPACK_PACKAGE_VERSION_MAJOR "${PROJECT_VERSION_MAJOR}")
set(CPACK_PACKAGE_VERSION_MINOR "${PROJECT_VERSION_MINOR}")
set(CPACK_PACKAGE_VERSION_PATCH "${PROJECT_VERSION_PATCH}")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "Carbon Services/Carbon ESG")
set(CPACK_PACKAGE_CONTACT "support@carbonservices.io")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/README.md")

if(WIN32)
    set(CPACK_GENERATOR "NSIS;ZIP")
    set(CPACK_PACKAGE_FILE_NAME "CarbonESG-${CARBON_ENGINE_VERSION}-Windows-x64")
    set(CPACK_NSIS_PACKAGE_NAME "Carbon ESG")
    set(CPACK_NSIS_DISPLAY_NAME "Carbon ESG")
    set(CPACK_NSIS_HELP_LINK "https://carbonservices.io")
    set(CPACK_NSIS_URL_INFO_ABOUT "https://carbonservices.io")
    set(CPACK_NSIS_CONTACT "support@carbonservices.io")
    set(CPACK_NSIS_MUI_ICON "${CMAKE_SOURCE_DIR}/src/apps/server/app.ico")
    set(CPACK_NSIS_MUI_UNIICON "${CMAKE_SOURCE_DIR}/src/apps/server/app.ico")
    set(CPACK_NSIS_MODIFY_PATH ON)
    set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
    set(CPACK_NSIS_MENU_LINKS
        "bin/carbon-engine-client.exe" "Carbon ESG"
        "bin/carbon-engine.exe" "Carbon Engine Daemon"
    )
else()
    set(CPACK_GENERATOR "DEB;TGZ")
    set(CPACK_PACKAGE_FILE_NAME "CarbonESG-${CARBON_ENGINE_VERSION}-Linux-x64")
    set(CPACK_DEBIAN_PACKAGE_NAME "carbon-esg")
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Carbon Services <support@carbonservices.io>")
    set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "Carbon ESG statutory BRSR reporting engine and desktop application by Carbon Services.")
    set(CPACK_DEBIAN_PACKAGE_SECTION "utils")
    set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
    set(CPACK_DEBIAN_PACKAGE_HOMEPAGE "https://carbonservices.io")
    set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS OFF)
    set(CPACK_DEBIAN_PACKAGE_DEPENDS "libgl1, libxkbcommon0")
endif()

include(CPack)

