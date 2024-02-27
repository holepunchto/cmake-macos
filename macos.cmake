set(macos_module_root ${CMAKE_CURRENT_LIST_DIR})

function(add_macos_bundle_info)
  cmake_parse_arguments(
    PARSE_ARGV 0 ARGV "" "DESTINATION;NAME;VERSION;DISPLAY_NAME;PUBLISHER_DISPLAY_NAME;IDENTIFIER;CATEGORY" ""
  )

  if(NOT ARGV_DESTINATION)
    set(ARGV_DESTINATION Info.plist)
  endif()

  if(NOT DEFINED ARGV_DISPLAY_NAME)
    set(ARGV_DISPLAY_NAME "${ARGV_NAME}")
  endif()

  file(READ "${macos_module_root}/Info.plist" template)

  string(CONFIGURE "${template}" template)

  file(GENERATE OUTPUT "${ARGV_DESTINATION}" CONTENT "${template}" NEWLINE_STYLE UNIX)
endfunction()

function(add_macos_bundle target)
  cmake_parse_arguments(
    PARSE_ARGV 1 ARGV "" "DESTINATION;INFO;ICON;TARGET;DEPENDS" ""
  )

  cmake_path(ABSOLUTE_PATH ARGV_DESTINATION BASE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}" NORMALIZE)

  cmake_path(GET ARGV_DESTINATION PARENT_PATH base)

  if(ARGV_TARGET)
    set(ARGV_EXECUTABLE $<TARGET_FILE:${ARGV_TARGET}>)

    set(ARGV_EXECUTABLE_NAME $<TARGET_FILE_NAME:${ARGV_TARGET}>)
  else()
    cmake_path(ABSOLUTE_PATH ARGV_EXECUTABLE NORMALIZE)

    cmake_path(GET ARGV_EXECUTABLE FILENAME ARGV_EXECUTABLE_NAME)
  endif()

  if(ARGV_INFO)
    cmake_path(ABSOLUTE_PATH ARGV_INFO NORMALIZE)
  else()
    cmake_path(APPEND base "Info.plist" OUTPUT_VARIABLE ARGV_INFO)
  endif()

  configure_file("${ARGV_INFO}" "${ARGV_DESTINATION}/Contents/Info.plist" COPYONLY)

  if(ARGV_ICON)
    configure_file("${ARGV_ICON}" "${ARGV_DESTINATION}/Contents/Resources/icon.icns" COPYONLY)
  endif()

  configure_file("${macos_module_root}/PkgInfo" "${ARGV_DESTINATION}/Contents/PkgInfo" COPYONLY)

  add_custom_target(
    ${target}_bin
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${ARGV_EXECUTABLE}" "${ARGV_DESTINATION}/Contents/MacOS/${ARGV_EXECUTABLE_NAME}"
  )

  list(APPEND ARGV_DEPENDS ${target}_bin)

  add_custom_target(
    ${target}
    ALL
    DEPENDS ${ARGV_DEPENDS}
  )
endfunction()
