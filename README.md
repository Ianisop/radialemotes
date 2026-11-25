# RadialEmotes

RadialEmotes is a World of Warcraft: Forever addon that lets you choose character emotes from a radial menu. Hold the wheel key to open it, choose an emote, and release the key to close it.

## Features

- Browse the emote list in pages, using the mouse wheel or the **Prev** and **Next** buttons.
- Reuse recently selected emotes from a first page that updates automatically.
- See your current target's portrait and name in the center of the wheel, or hide that panel in settings.
- Choose between 6 and 12 emotes per page, and adjust the wheel size.
- Keep the wheel open after choosing an emote, or have it close automatically.
- Have the wheel close automatically when combat begins.
- Use the hold-to-open binding or toggle the wheel with a slash command.

## Install

Download RadialEmotes from the [CurseForge project page](https://www.curseforge.com/wow/addons/radialemotes).

To install from this source repository, put the `RadialEmotes` folder, including `RadialEmotes.toc`, `RadialEmotes.lua`, `Bindings.xml`, and the artwork files, in your WoW Forever AddOns directory:

```text
World of Warcraft/_forever_/Interface/AddOns/RadialEmotes/
```

Enable **RadialEmotes** on the character selection AddOns screen, then enter the game or reload the UI with `/reload`.

## Use

Set the hold key under **Options → Key Bindings → RadialEmotes → Hold Emote Wheel**. Hold it to display the wheel, click an emote to perform it, then release the key to hide the wheel. Your most recently selected unique emotes appear on the **Recent Emotes** page, newest first. Use the mouse wheel or the on-screen buttons to change pages. Press **Escape** to hide the wheel.

These commands toggle the wheel:

```text
/re
/radialemotes
/ew
/emotewheel
```

Open addon settings with:

```text
/re options
```

`/re config` and `/re settings` are also accepted. Settings are under **Options → AddOns → RadialEmotes**. They control wheel size, emotes per page, the target display, mouse-wheel paging, and whether the wheel closes after selecting an emote.

## Compatibility

The addon TOC declares interface versions `16001` and `11509`. The available emotes come from a built-in token list, supplemented by localized emote tokens exposed by the client.

## Project files

- `RadialEmotes.lua` contains the addon behavior and settings.
- `RadialEmotes.toc` declares metadata, saved variables, and the Lua entry point.
- `Bindings.xml` defines the hold-to-open key binding.
- `WheelBackdrop` and `TargetMedallion` artwork are included as SVG source and TGA game assets.
- `CHANGELOG.md` records release changes.

## Contributing

Bug reports and changes are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the contribution and manual verification process.

## License

RadialEmotes is released under the MIT License. See [LICENSE](LICENSE).
