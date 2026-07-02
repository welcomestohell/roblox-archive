# Welcome To Hell

VNG በጣም መጥፎው ኩባንያ ነው እና በቪየትናም ROBLOX ላይ ያላቸውን ገደብ በእነርሱ ስግብግብነት 
እናምጻለን ጨዋታዎችን መከልከል ህገ-ወጥ ናቸው, እኛን ዝም ማለት ሰብአዊ መብት አይደለም እኛን 
ከመከራ በስተቀር ምንም አላመጡልንም

![Welcome To Hell](./assets/github/banner.jpeg)

## Structure

Starting with least dependencies:

- `libs`: Welcome To Hell's standard libraries. Dump any helpers into this
  folder. Keep it flat when possible, so require paths are concise and brief.
  `libs/std.luau` should have as little imports as possible. To avoid cyclic
  dependencies, don't depend on `libs/std.luau` ever. Unless you're writing
  tower scripts.
- `core`: Core providers, UI components, etc used everywhere in Welcome To Hell.
  To be consumed by the `towerkit` and `editor` alongside the `game`.
- `universe`: Game specific providers, UI components, etc used in the Welcome To
  Hell places. Kept separate from `core` as to not expose anything into `kit`.
- `chapter`: Chapter specific providers, UI components, etc used throughout all
  campaign chapters. Kept separate from `game` as to not expose anything into
  `title`.
- `title`: The title screen, or spawn game, of Welcome To Hell.
- `chapter1`, `chapter2`, etc: Individual chapters of Welcome To Hell.

## Style

- LOUD_SNAKE_CASE for constant variables
- PascalCase for attributes, classes, types
- camelCase for everything else including library names
- Prefix private variables with `_`
- Name modules based on it's export/import (ie. Life is called Life.luau)
- Conform to stylua when possible

## Development

Prerequisites:

- Rokit: <https://github.com/rojo-rbx/rokit>
- VSCode or Zed

```sh
# Clone the repository
git clone https://github.com/welcomestohell/game.git

# Install tools
rokit install

# Install Rojo plugin
rojo plugin install

# Install pesde packages
pesde install

# Start development session:
rose dev chapter1 
rose dev kit
rose dev ...
```

Welcome To Hell uses our own monorepository build tool. Documentation for it
can be found here: <https://github.com/teamfireworks/rose>

### Troubleshooting

#### `libs/activation/init` error at runtime (or require paths with init at the end)

You imported `@libs/activation/init` which is wrong. Change it to `@libs/activation`.

Rose source transformers should fix this but we're not interested in spending
more time on Rose right now.

#### XYZ file/folder doesn't exist

Some files are hidden via `.vscode/settings.json` and `.zed/settings.json` to
make the repository nicer. If you need access to the build files for whatever
reasons, try untoggling the excluded files.

#### "The address may already be in use or reserved. Another Rojo server might already be running, or another program may be using that port."

Run one of these commands to kill the Rojo process:

```sh
# Unix
kill -9 $(lsof -t -i:34872)

# Windows
Stop-Process -Id (Get-NetTCPConnection -LocalPort 34872).OwningProcess -Force
```

Generally, don't exit using `rose dev`'s actions yet, as it's buggy.
