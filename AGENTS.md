# Emboscao!! — agent guide

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

Addon files at the repo root, packaged as the folder `Emboscao` (`.pkgmeta`):

- `Emboscao.toc` (load order), `Emboscao.lua` (entry point: events, `/emboscao`, `/embos`; does nothing on non-rogues)
- `Localization/Locale.lua` — English text is the key, with the Spanish table (a test checks every key has one)
- `Modules/Settings/` — per character or account-wide settings (same scheme as Aggreao), defaults in `ns.DEFAULTS`
- `Modules/Rogue/` — game logic without UI: `Combo`, `Energy` (tick detection from energy rises), `Poisons`
  (`GetWeaponEnchantInfo`), `Reagents`, `Auras` (timers by localized spell name); tests in `Rogue.test.lua`
- `Modules/Rogue/PoisonTypes.lua` — every Forever poison by type and rank (recipe spell, item, reagents; copied from
  Fabrikao's Forever recipe data, skill line 40), what you carry / know / can make of each, and the type each hand gets
  (`poisonMainType` / `poisonOffType`: "auto", "none" or a type)
- `Modules/UI/` — `Hud` (the bars), `Alerts` (the reminder; each poison icon gets a hidden `SecureActionButtonTemplate`
  over it with the macro `/use item:<poison>` + `/use <slot>`, live only locked and out of combat, hidden on
  PLAYER_REGEN_DISABLED and never touched in combat), `Preferences` (two-column window, color picker for both
  the old and the 10.2.5+ `ColorPickerFrame` API); tests in `UI.test.lua`
- `test/` (WoW API mock + local runner), `setupTests.lua`
- `Icons/Emboscao.png` (256x256, transparent): drawn as `images/icon.svg` in the siblings' style with a purple background
  (Completao green, Embolsao gold, Aggreao blue, Fabrikao red). Re-render after editing the SVG with headless Chrome:
  `chrome --headless=new --default-background-color=00000000 --window-size=256,256 --screenshot=<repo>\Icons\Emboscao.png file:///<repo>/images/icon.html`

## Commands (repo root)

```powershell
lua test/busted.lua                       # all tests, no busted install needed
luacheck -q -- Emboscao.lua Localization Modules Emboscao.test.lua test setupTests.lua
```

Deploy to the Forever client (PowerShell; robocopy exit codes 0-7 are success):
`robocopy . "D:\Games\World of Warcraft\_forever_\Interface\AddOns\Emboscao" *.lua *.toc *.png /S /PURGE /XD test images .github .git .claude /XF *.test.lua setupTests.lua`

## Code conventions

- Lua 5.1. `local ADDON, ns = ...` in every file; no new globals (see `.luacheckrc`; game API globals go in `read_globals`).
- Tests set game globals through `_G.X = ...` (the runner sandboxes plain assignments).
- **Secret values**: Forever hides some numbers from addons (your energy even out of combat; maybe combo points,
  auras, weapon enchants in combat). Never compare or do arithmetic with a game value without `ns.IsSecret`
  (`Modules/Core/Secret.lua`); hand secrets straight to the widgets (`StatusBar:SetValue`, `FontString:SetText`). The
  combo points are one StatusBar per point (min i-1, max i) for that reason, and the energy tick falls back to "a change
  not right after a cast" when the energy is secret.
- Optional game events are registered with `pcall` (an unknown event errors on some clients).
- Commit style: `feat(scope):`, `fix(scope):`, `release: X.Y.Z -- short summary`. User-visible changes go in `CHANGELOG.md`.
