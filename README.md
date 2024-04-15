# cmake-macos

## API

#### `find_codesign(<result>)`

#### `find_iconutil(<result>)`

#### `add_macos_entitlements([DESTINATION <path>] ENTITLEMENTS <entitlement...>)`

#### `add_macos_iconset([DESTINATION <path>] ICONS [<path> 16|32|64|128|256|512 1x|2x]... [DEPENDS <target...>])`

#### `add_macos_bundle_info(<target> [DESTINATION <path>] NAME <string> VERSION <string> DISPLAY_NAME <string> PUBLISHER_DISPLAY_NAME <string> IDENTIFIER <identifier> CATEGORY <string> [TARGET <target>] [EXECUTABLE <path>])`

#### `add_macos_bundle(<target> DESTINATION <path> [INFO <path>] [ICON <path>] [TARGET <target>] [EXECUTABLE <path>] [RESOURCES [FILE|DIR <from> <to>]...] [DEPENDS <target...>])`

#### `code_sign_macos(<target> [PATH <path>] [TARGET <target>] [ENTITLEMENTS <path>] IDENTITY <string> [KEYCHAIN <string>] [DEPENDS <target...>])`

## License

Apache-2.0
