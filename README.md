# herdr-navigator.nvim

A tool providing seamless navigation between Neovim splits
and [Herdr](https://herdr.dev/) terminal multiplexer panes.
It works similarly to `vim-tmux-navigator` but specifically for Herdr.

This project consists of two parts:
1. A Neovim plugin to handle navigation from within Neovim.
2. A companion CLI tool (`herdr-navigator` in `src/`) to be invoked by Herdr when
the user wants to switch active pane.

## Requirements
- Neovim >= 0.9.0 (at least, tested for 0.12.0 and 0.13.0-nightly)
- [Herdr](https://herdr.dev/) terminal multiplexer
- Linux (recommended, but will probably work even on non-unix OSes too)

## Installation
### Neovim Plugin

Install the plugin using your preferred package manager.
For example, with [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
  "joo-was-already-taken/herdr-navigator.nvim",
  -- Default configuration:
  opts = {
    enabled = function() return true end,
    keys = {
      left = "<C-h>",
      right = "<C-l>",
      up = "<C-k>",
      down = "<C-j>",
    },
  },
}
```

The plugin automatically sets up the keybindings (`<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`)
to navigate between Neovim splits, falling back to Herdr pane navigation.

### CLI Tool

You also need to install the companion CLI tool, which is used to detect
if Neovim is running in the active pane in order to reroute keypresses accordingly.

#### Nix
The flake in this repository exposes both the CLI tool and the Neovim plugin.

```nix
# Cli
inputs.herdr-navigator.packages.${system}.herdr-navigator
# Neovim plugin
inputs.herdr-navigator.packages.${system}.herdr-navigator-nvim
```


#### Cargo:
```bash
cargo install --git https://github.com/joo-was-already-taken/herdr-navigator.nvim
```
Make sure the installed binary (`herdr-navigator`) is in your system's `$PATH`.

## Configuration
### herdr Configuration
Add this to your `herdr/config.toml` in your config dir, adjusting keys to your liking.
The key passed with `--key` flag is a key that will be passed to the Neovim process.
```toml
[[keys.command]]
key = "ctrl+h"
command = "herdr-navigator left --key ctrl+h"
[[keys.command]]
key = "ctrl+l"
command = "herdr-navigator right --key ctrl+l"
[[keys.command]]
key = "ctrl+k"
command = "herdr-navigator up --key ctrl+k"
[[keys.command]]
key = "ctrl+j"
command = "herdr-navigator down --key ctrl+j"
```

## License
[MIT](./LICENSE)
