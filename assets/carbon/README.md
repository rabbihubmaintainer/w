# Optional IBM Plex Sans typeface

The interface defaults to Roblox's built-in Builder Sans. These files support the
optional IBM Plex Sans choice in the appearance settings.

The unmodified regular and semibold font files come from
[IBM Plex](https://github.com/IBM/plex/tree/master/packages/plex-sans/fonts/complete/ttf).
They are distributed under the SIL Open Font License in [OFL.txt](OFL.txt).

The library caches these files under `rabbihub/assets/carbon` and builds a local
Roblox font-family descriptor when the executor supports custom font assets.
If that capability or the download is unavailable, it uses Roblox's built-in
Roboto font. Selecting a different typeface remains supported.
