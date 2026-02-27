# Contributing

## Running Tests

The test suite uses [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)'s busted-style harness, so tests run inside a real headless Neovim instance and can exercise `vim.api`, buffers, and windows directly.

### Installing `plenary.nvim`

The simplest option is to install `plenary.nvim` in your normal Neovim config with your usual plugin manager.

If you use `lazy.nvim`, add:

```lua
{
    "nvim-lua/plenary.nvim",
}
```

Then restart Neovim and run `:Lazy sync` or `:Lazy install`.

If you do not want to install it permanently, you can clone it locally and point `PLENARY_PATH` at that checkout when running tests:

```sh
git clone https://github.com/nvim-lua/plenary.nvim ~/src/plenary.nvim
PLENARY_PATH=~/src/plenary.nvim make test
```

If `plenary.nvim` is already installed as a package, run:

```sh
nvim --headless -u tests/minimal_init.lua -i NONE \
  -c "PlenaryBustedDirectory tests { minimal_init = 'tests/minimal_init.lua' }" \
  -c qa
```

If it is not installed, point `PLENARY_PATH` at a local checkout:

```sh
PLENARY_PATH=/path/to/plenary.nvim \
nvim --headless -u tests/minimal_init.lua -i NONE \
  -c "PlenaryBustedDirectory tests { minimal_init = 'tests/minimal_init.lua' }" \
  -c qa
```

With the included `Makefile`, you can also run:

```sh
make test
```
