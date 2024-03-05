set(macos_module_root ${CMAKE_CURRENT_LIST_DIR})

function(find_codesign result)
  find_program(
    codesign
    NAMES codesign
    REQUIRED
  )

  set(${result} "${codesign}")

  return(PROPAGATE ${result})
endfunction()

function(add_macos_entitlements target)
  set(one_value_keywords
    DESTINATION
  )

  set(multi_value_keywords
    ENTITLEMENTS
  )

  cmake_parse_arguments(
    PARSE_ARGV 1 ARGV "" "${one_value_keywords}" "${multi_value_keywords}"
  )

  if(NOT ARGV_DESTINATION)
    set(ARGV_DESTINATION Entitlements.plist)
  endif()

  cmake_path(ABSOLUTE_PATH ARGV_DESTINATION BASE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}" NORMALIZE)

  list(TRANSFORM ARGV_ENTITLEMENTS PREPEND "  <key>")

  list(TRANSFORM ARGV_ENTITLEMENTS APPEND "</key>\n  <true/>")

  list(JOIN ARGV_ENTITLEMENTS "\n" ARGV_ENTITLEMENTS)

  file(READ "${macos_module_root}/Entitlements.plist" template)

  string(CONFIGURE "${template}" template)

  file(GENERATE OUTPUT "${ARGV_DESTINATION}" CONTENT "${template}" NEWLINE_STYLE UNIX)
endfunction()

function(add_macos_bundle_info target)
  set(one_value_keywords
    DESTINATION
    NAME
    VERSION
    DISPLAY_NAME
    PUBLISHER_DISPLAY_NAME
    IDENTIFIER
    CATEGORY
    TARGET
    EXECUTABLE
  )

  cmake_parse_arguments(
    PARSE_ARGV 1 ARGV "" "${one_value_keywords}" ""
  )

  if(NOT ARGV_DESTINATION)
    set(ARGV_DESTINATION Info.plist)
  endif()

  cmake_path(ABSOLUTE_PATH ARGV_DESTINATION BASE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}" NORMALIZE)

  if(ARGV_TARGET)
    set(ARGV_EXECUTABLE $<TARGET_FILE:${ARGV_TARGET}>)

    set(ARGV_EXECUTABLE_NAME $<TARGET_FILE_NAME:${ARGV_TARGET}>)
  else()
    cmake_path(ABSOLUTE_PATH ARGV_EXECUTABLE NORMALIZE)

    cmake_path(GET ARGV_EXECUTABLE FILENAME ARGV_EXECUTABLE_NAME)
  endif()

  if(NOT DEFINED ARGV_DISPLAY_NAME)
    set(ARGV_DISPLAY_NAME "${ARGV_NAME}")
  endif()

  file(READ "${macos_module_root}/Info.plist" template)

  string(CONFIGURE "${template}" template)

  file(GENERATE OUTPUT "${ARGV_DESTINATION}" CONTENT "${template}" NEWLINE_STYLE UNIX)
endfunction()

function(add_macos_bundle target)
  set(one_value_keywords
    DESTINATION
    INFO
    ICON
    TARGET
  )

  set(multi_value_keywords
    RESOURCES
    DEPENDS
  )

  cmake_parse_arguments(
    PARSE_ARGV 1 ARGV "" "${one_value_keywords}" "${multi_value_keywords}"
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

  cmake_path(ABSOLUTE_PATH ARGV_ICON NORMALIZE)

  list(APPEND commands
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${ARGV_INFO}" "${ARGV_DESTINATION}/Contents/Info.plist"
  )

  if(ARGV_ICON)
    list(APPEND ARGV_RESOURCES FILE "${ARGV_ICON}" "icon.icns")
  endif()

  while(TRUE)
    list(LENGTH ARGV_RESOURCES len)

    if(len LESS 3)
      break()
    endif()

    list(POP_FRONT ARGV_RESOURCES type from to)

    cmake_path(ABSOLUTE_PATH from NORMALIZE)

    if(type MATCHES "FILE")
      set(command copy_if_different)
    elseif(type MATCHES "DIR")
      set(command copy_directory_if_different)
    else()
      continue()
    endif()

    list(APPEND commands
      COMMAND ${CMAKE_COMMAND} -E ${command} "${from}" "${ARGV_DESTINATION}/Contents/Resources/${to}"
    )
  endwhile()

  list(APPEND commands
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${ARGV_EXECUTABLE}" "${ARGV_DESTINATION}/Contents/MacOS/${ARGV_EXECUTABLE_NAME}"

    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${macos_module_root}/PkgInfo" "${ARGV_DESTINATION}/Contents/PkgInfo"
  )

  add_custom_target(
    ${target}
    ALL
    ${commands}
    DEPENDS ${ARGV_DEPENDS}
  )
endfunction()

function(code_sign_macos_bundle target)
  set(one_value_keywords
    PATH
    ENTITLEMENTS
    IDENTITY
    KEYCHAIN
  )

  set(multi_value_keywords
    DEPENDS
  )

  cmake_parse_arguments(
    PARSE_ARGV 1 ARGV "" "${one_value_keywords}" "${multi_value_keywords}"
  )

  if(NOT ARGV_IDENTITY)
    set(ARGV_IDENTITY "Apple Development")
  endif()

  cmake_path(ABSOLUTE_PATH ARGV_PATH NORMALIZE)

  cmake_path(GET ARGV_PATH PARENT_PATH base)

  if(ARGV_ENTITLEMENTS)
    cmake_path(ABSOLUTE_PATH ARGV_ENTITLEMENTS NORMALIZE)
  else()
    cmake_path(APPEND base "Entitlements.plist" OUTPUT_VARIABLE ARGV_ENTITLEMENTS)
  endif()

  list(APPEND args --force --sign "${ARGV_IDENTITY}" --entitlements "${ARGV_ENTITLEMENTS}")

  if(ARGS_KEYCHAIN)
    list(APPEND args --keychain "${ARGV_KEYCHAIN}")
  endif()

  find_codesign(codesign)

  add_custom_target(
    ${target}
    ALL
    COMMAND ${codesign} ${args} "${ARGV_PATH}"
    DEPENDS ${ARGV_DEPENDS}
  )
endfunction()
