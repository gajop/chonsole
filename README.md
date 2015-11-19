Modern chili console for the Spring Engine.

## Features
- history persistant through restarts, history autocomplete
- detailed command overview
- custom command support (/gamerules, /execw, etc.)
- integration with liblobby for Spring lobby communication
- i18n

## Dependencies
- Spring 101.x+
- [chili](https://github.com/gajop/chiliui)
- [liblobby](https://github.com/gajop/liblobby) (optional, support for Spring lobby communication)
- [i18n](https://github.com/gajop/i18n) (optional, support for i18n)

## Install
1. Obtain the repository either by adding it as a git submodule or by copying the entire structure in to your Spring game folder. Put it anywhere (although /libs is suggested and used by default).
2. Copy the file ui_chonsole_load.lua to the luaui/widgets and luarules/gadgets folders and modify the CHONSOLE_FOLDER path.

## Customization
TODO