# Carbon-inspired interface

The UI follows the color, typography, spacing, and component patterns of
[IBM's Carbon Design System](https://carbondesignsystem.com/). It is implemented
with native Roblox GUI objects, rather than the Carbon web component library.

`Library.lua`, `ThemeManager.lua`, `SaveManager.lua`, and the window configuration
in `internalscript.lua` are updated together. The modular `src/ui` entry point
uses the same window and theme defaults.

- Gray 100 is the initial palette. Gray 90, White, and Gray 10 presets are available
  under Config → Appearance. Existing named and custom themes remain available.
- IBM Plex Sans uses the bundled regular/semibold font files when custom font
  assets are supported. Roboto is the fallback.
- Square panels, a 48 px dark header, left navigation with a blue selection bar,
  restrained borders, and a 4/8/16/24 px spacing rhythm replace the previous style.
- Fields and actions are 40 px tall. Sliders separate the value from the track.
  Focus outlines, semantic text roles, and primary/secondary/danger/ghost action
  variants remain consistent when switching themes.
- Content changes to a single column when the available content width is below
  560 px. The normal left/right panel arrangement returns when space is available.
- Theme files now retain the complete color-role set and the selected typeface.
  Configuration files retain their existing format and do not override appearance.

## Verification

With Python 3 and the Luau CLI installed:

```sh
luau-compile --null Library.lua ThemeManager.lua SaveManager.lua internalscript.lua
python3 tests/run_ui_tests.py --luau /path/to/luau
python3 tests/run_unload_tests.py --luau /path/to/luau
```

The UI checks execute the real library/managers against offline API doubles.
They cover theme selection and persistence, custom-font setup/fallback, measured
text/action contrast for the four presets, focus behavior, control callbacks,
dropdown sizing, configuration round trips, responsive columns, and unload.
The original 26 unload regressions also remain in place.

API doubles and their approximate layout snapshots do not replace Roblox testing.
In-game verification should cover loading an existing configuration/theme, opening
pickers and menus, scrolling long tabs, narrow windows, and unloading/reloading.
