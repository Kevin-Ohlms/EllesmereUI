# EllesmereUI Unit Tests


This directory contains the unit test setup for the EllesmereUI addon core using [WoWUnit](https://github.com/Jaliborc/WoWUnit).
Tests run outside World of Warcraft using a minimal WoW API bootstrap and the WoWUnit Lua testing framework.

## Structure


- `bootstrap.lua` - test environment loader with minimal WoW API stubs (if needed)
- `test_ellesmereui.lua` - example unit tests for core helper functions


## Prerequisites

- Lua 5.1 (e.g., [Lua for Windows](https://github.com/rjpcomputing/luaforwindows) or [LuaBinaries](https://sourceforge.net/projects/luabinaries/))
- [WoWUnit](https://github.com/Jaliborc/WoWUnit)

## Setup

1. Download WoWUnit and place `WoWUnit.lua` (and the folder if needed) in your `tests/` directory.
2. Write your test files in `tests/`.

## Run Tests

```bash
lua tests/test_ellesmereui.lua
```

See WoWUnit documentation for more advanced usage.

For Windows, WSL is often the most stable environment for Lua 5.1 tests.

1. Open WSL
2. Install `lua5.1`, `lua5.1-dev` and `luarocks`
3. Run `./tests/run-tests.sh`

If you use UV, install Lua 5.1 through UV and then run tests with `uv run`.
