# summon.nvim

A Neovim plugin for launching terminal commands in persistent floating windows.

## Installation

### lazy.nvim

```lua
{
    "salkhalil/summon.nvim",
    opts = {},
}
```

### Local development

```lua
{
    dir = "~/Documents/apps/summon.nvim",
    opts = {},
}
```

## Configuration

Calling `setup()` with no arguments gives you a single floating terminal running `claude` on `<leader>c`.

```lua
require("summon").setup({
    -- Global defaults (apply to all commands unless overridden)
    width = 0.85,
    height = 0.85,
    border = "rounded",
    close_keymap = "<Esc><Esc>",
    highlights = {
        float = { bg = "#282828" },
        border = { fg = "#d79921", bg = "#282828" },
        title = { fg = "#282828", bg = "#d79921", bold = true },
    },

    -- Named commands
    commands = {
        claude = {
            command = "claude",
            title = " Claude ",
            keymap = "<leader>c",
        },
        lazygit = {
            command = "lazygit",
            title = " LazyGit ",
            keymap = "<leader>gg",
            height = 0.9, -- override global default
        },
    },
})
```

### Command options

Each entry in `commands` supports:

| Option | Description | Default |
|---|---|---|
| `command` | Shell command to run | (required) |
| `title` | Float window title | `" <name> "` |
| `keymap` | Normal mode keymap to open | `nil` (no binding) |
| `width` | Float width (0-1 ratio) | Global `width` |
| `height` | Float height (0-1 ratio) | Global `height` |
| `border` | Border style | Global `border` |
| `close_keymap` | Terminal mode keymap to dismiss | Global `close_keymap` |

## Usage

### Keymaps

Keymaps defined in `commands` open the corresponding float directly. The default config binds `<leader>c` to open Claude.

### Commands

```vim
:Summon claude     " open a specific command by name
:Summon lazygit
:Summon            " opens automatically if only one command is configured
```

`:Summon` supports tab completion for command names.

### Behaviour

- Terminal buffers persist after closing the float — reopening reattaches to the same session.
- Each command gets its own independent buffer.
- Close the float with `<Esc><Esc>` (configurable) without killing the process.
