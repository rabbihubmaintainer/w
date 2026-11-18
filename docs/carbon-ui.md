# Catppuccin interface

The native Roblox interface uses Catppuccin Mocha, softer cards, clear text
hierarchy, and a responsive layout. The earlier Carbon palettes remain available.

`Library.lua`, `ThemeManager.lua`, `SaveManager.lua`, and the window configuration
in `internalscript.lua` are updated together. The modular `src/ui` entry point
uses the same window and theme defaults.

- Catppuccin Mocha is the initial and reset palette, with a mauve accent and dark
  text on its lighter actions. Carbon Gray 100, Gray 90, White, and Gray 10 remain
  available under Config → Appearance. Explicitly saved theme choices are respected.
- Builder Sans is the default typeface, with 15 px body labels and semibold
  headings. IBM Plex Sans remains selectable; its bundled font files are used
  when custom font assets are supported, with Roboto as a fallback.
- Rounded cards and fields, a 60 px header, and a subtle mauve navigation state
  replace the heavier outlines. Panel content has an explicit header offset and
  measured height; layout spacers no longer rely on Roblox's default Frame size.
- Fields and actions are 40 px tall. All sliders, including compact sliders,
  have a full setting label, a numeric badge, and a full-width track below.
  Long labels wrap and increase the row height rather than spilling or shrinking.
  Focus outlines, semantic text roles, and primary/secondary/danger/ghost action
  variants remain consistent when switching themes.
- Content changes to a single column when the available content width is below
  560 px. The normal left/right panel arrangement returns when space is available.
- The window follows camera/viewport size changes, stays within the screen,
  respects manual resize preferences, and increases its scale on larger displays.
  Automatic layout does not shrink the base font on small screens; content reflows
  and scrolls instead. Camera replacement and repeated DPI changes are handled.
- Theme files now retain the complete color-role set and the selected typeface.
  Configuration files retain their existing format and do not override appearance.
- Navigation, search, switches/pickers, and manager icons use bundled native UI
  shapes. The icon loader no longer downloads or executes an external icon script.
  Unknown icon names use a grid fallback; Roblox image assets remain supported.
  Use `Library:SetIcon(imageLabel, Library:GetIcon(name))` to attach a bundled icon
  to an image label created outside the library.
- World ESP text and the aim FOV circle are hidden while the menu is open so they
  do not draw above its panels. Closing the menu restores their normal rendering.

## Verification

With Python 3 and the Luau CLI installed:

```sh
luau-compile --null Library.lua ThemeManager.lua SaveManager.lua internalscript.lua
python3 tests/run_ui_tests.py --luau /path/to/luau
python3 tests/run_unload_tests.py --luau /path/to/luau
```

The UI checks execute the real library/managers against offline API doubles.
They cover theme selection and persistence, custom-font setup/fallback, measured
text/action contrast, focus behavior, control callbacks, dropdown sizing,
configuration round trips, the reported compact-slider text regression, panel
header clearance, long labels, viewport sizes from 360×640 to 4K, repeated DPI
changes, camera replacement, overlay occlusion, and unload.
The original 26 unload regressions also remain in place.

API doubles and their approximate layout snapshots do not replace Roblox testing.
In-game verification should cover loading an existing configuration/theme, opening
pickers and menus, scrolling long tabs, narrow windows, and unloading/reloading.
