# Apicarao!! — agent guide

World of Warcraft addon: a rogue toolset. Movable combo point bars (one bar per point, side by side, no window; sizes and
colors configurable), energy bar with the 2-second tick spark, duration bars (Slice and Dice, your Rupture / Garrote /
Expose Armor on the target), and a movable reminder for poisons missing or about to end (configurable minutes and charges)
and low reagents (Flash Powder, Blinding Powder). Cooldowns are left out on purpose: the game's own cooldown manager shows
them. Only WoW Forever for now (`## Interface: 16001`). Siblings with the same conventions under `D:\Source\WowAddons\`:
`Aggreao` (the template this repo was cloned from), `Completao`, `Embolsao`, `Fabrikao`.

## How to work with the maintainer

- **Chat in Spanish from Spain** ("tú", never voseo). **Everything committed is in English**; Spanish only in the esES/esMX
  table of `Localization/Locale.lua` and the esES/esMX TOC notes.
- Windows machine. Multi-line commit messages: write a file and use `git commit -F <file>`.
- Merging to `master` and releasing only happen when the maintainer asks.

## Layout

Addon files at the repo root, packaged as the folder `Apicarao` (`.pkgmeta`):

- `Apicarao.toc` (load order), `Apicarao.lua` (entry point: events, `/apicarao`, `/apic`; does nothing on non-rogues)
- `Localization/Locale.lua` — English text is the key, with the Spanish table (a test checks every key has one)
- `Modules/Settings/` — per character or account-wide settings (same scheme as Aggreao), defaults in `ns.DEFAULTS`
- `Modules/Rogue/` — game logic without UI: `Combo`, `Energy` (tick detection from energy rises), `Poisons`
  (`GetWeaponEnchantInfo`), `Reagents`, `Auras` (timers by localized spell name); tests in `Rogue.test.lua`
- `Modules/UI/` — `Hud` (the bars), `Alerts` (the reminder), `Preferences` (two-column window, color picker for both
  the old and the 10.2.5+ `ColorPickerFrame` API); tests in `UI.test.lua`
- `test/` (WoW API mock + local runner), `setupTests.lua`

## Commands (repo root)

```powershell
lua test/busted.lua                       # all tests, no busted install needed
luacheck -q -- Apicarao.lua Localization Modules Apicarao.test.lua test setupTests.lua
```

Deploy to the Forever client (PowerShell; robocopy exit codes 0-7 are success):
`robocopy . "D:\Games\World of Warcraft\_forever_\Interface\AddOns\Apicarao" *.lua *.toc /S /PURGE /XD test .github .git .claude /XF *.test.lua setupTests.lua`

## Code conventions

- Lua 5.1. `local ADDON, ns = ...` in every file; no new globals (see `.luacheckrc`; game API globals go in `read_globals`).
- Tests set game globals through `_G.X = ...` (the runner sandboxes plain assignments).
- Optional game events are registered with `pcall` (an unknown event errors on some clients).
- Commit style: `feat(scope):`, `fix(scope):`, `release: X.Y.Z -- short summary`. User-visible changes go in `CHANGELOG.md`.
