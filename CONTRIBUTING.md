# Contributing

Thanks for helping improve RadialEmotes. Keep changes focused, describe the player-facing effect, and include enough detail for someone else to review or reproduce the change.

## Before you start

- Check the existing [README](README.md) and [changelog](CHANGELOG.md) for current behavior and project conventions.
- For a bug report, include your WoW Forever client/interface version, the steps to reproduce it, what you expected, and what happened. Include relevant Lua errors from the game if available.
- For a feature proposal, explain the use case and how you expect it to work in the wheel.

## Making a change

1. Fork the repository or create a branch for your change.
2. Keep edits scoped to the issue. The addon is self-contained: behavior and settings are in `RadialEmotes.lua`, addon metadata is in `RadialEmotes.toc`, and the key binding is in `Bindings.xml`.
3. Preserve compatibility with the interface versions declared in the TOC (`16001` and `11509`) unless the change intentionally updates the supported clients.
4. Keep the standalone addon folder installable. If you add an asset, include it in the addon package and update the TOC or documentation as appropriate.
5. Update `CHANGELOG.md` for user-visible changes intended for a release.

There is currently no build system or automated test suite. Do not add generated archives to a source change unless a release specifically requires them.

## Manual verification

When you can run the addon in WoW Forever, install the changed folder and check the relevant behavior in game. For changes to the wheel or its input, useful checks include:

- The addon loads without Lua errors and `/re` opens and closes the wheel.
- The hold binding opens while pressed and hides on release; **Escape** also hides it.
- Clicking an emote performs it, paging works, and the configured close-after-selection behavior is respected.
- Settings apply to wheel size, page size, target display, and mouse-wheel paging.
- The wheel closes on entering combat.

If you cannot test in game, say so in the pull request and describe any checks you did perform. Do not claim a game-client test that was not run.

## Submitting a change

- Use a clear title and explain the problem and the change in the pull request description.
- Include reproduction steps or manual verification results when relevant.
- Link related issues and add screenshots or a short recording for visual changes when useful.
- Keep unrelated formatting or refactoring out of the change so review stays focused.

## Releases

Release packaging should keep the `RadialEmotes` folder at the archive root, with `RadialEmotes.toc`, `RadialEmotes.lua`, `Bindings.xml`, required artwork, and the project documentation included. Update the TOC version and changelog together for a release.
