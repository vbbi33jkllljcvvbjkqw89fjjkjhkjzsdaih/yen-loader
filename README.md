# Yen Loader (private)

The entry point and the game checker. Decides which game you are in and loads that game's script.

- `Loader.lua` — entry. Runs the key system, then checks the game, then loads the game's script.
- `Games.lua` — the supported games list. Each entry matches by PlaceId or universe GameId and names the script and features to load. Slayers 2 is the only game right now.
- `Import.lua` — the module and asset loader (dev files, or the embedded bundle). Pulls Farcal and Obsidian from their public sources.
- `Hub.lua` — the shared UI framework every game builds on (tabs, feature system, settings, diagnostics, dual theme).
- `Theme.lua`, `Assets/logo.png` — the silver theme and logo.

Flow: `Loader.lua` → key system (yen-keysystem) → `Games.lua` finds your game → loads that game's module (yen-slayers2). Private. Review copy of `Documents\Yen\src`.
