# Developing Welcome To Hell

```sh
# install toolchain
rokit install

# locally bootstrap the repository
lute setup

# install all packages if you wanna
pesde install

# list out all the scripts you can run
lute scripts

# all commands have --help
lute dev --help

# dev command has a built-in menu, try it out!
lute dev title

# when you're done with libs, core, game, or chapter, deploy all places
lute deploy

# one will do just fine
lute deploy title

# need to run something inside all folders?
lute ripple blink --watch .blink
```

## Configuration

All place configuration will be done under the `wth` field inside `.config.luau`
files. Repository `.config.luau` is self-explanatory, so we'll explain workspace
members' `.config.luau`'s:

```luau
return {
    wth = {
        -- scripts treat a folder as a workspace member if it's .config.luau
        -- specifies the workspace field
        place = {
            -- metadata
            title = "Chapter 1",
            subtitle = "A Star Upon A Child",

            -- specifying placeId allows you to quick-open and dev this member
            placeId = "1234567890",

            -- specify dependencies for rojo
            -- scripts will resolve dependencies recursively, ie. depending on
            -- chapter will pull in all of it's dependencies
            dependencies = { "chapter" },

            -- folder name to be used by rojo
            folderName = "Chapter1",
        },

        -- specifies a child to be added across all build targets
        -- is mutually exclusive to place
        placeMixin = {
            folderName = "Libs",
            rojo = {
                { name = "ReplicatedStorage" }
            }
        }
    }
}
```

## Structure

I care about your eyes, so all workspace members are placed at the repository's
root. Isn't it beautiful?

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

Code is copied and transformed inside the `out` folder.
