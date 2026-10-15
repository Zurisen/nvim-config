# nvim-config

Personal Neovim config for C#, Python and TypeScript development on Windows.
Built on [lazy.nvim](https://github.com/folke/lazy.nvim) with the
[Dracula](https://github.com/Mofiqul/dracula.nvim) theme (as in VS Code).

## What's included

| Area        | Plugins / tools                                                      |
|-------------|----------------------------------------------------------------------|
| LSP         | roslyn.nvim (C#), basedpyright + ruff (Python), vtsls (TypeScript), lua_ls |
| Completion  | blink.cmp + friendly-snippets                                        |
| Syntax      | nvim-treesitter (`main` branch)                                      |
| Formatting  | conform.nvim — csharpier, ruff, prettierd, stylua (format on save)   |
| Debugging   | nvim-dap + dap-ui — netcoredbg, debugpy, js-debug                    |
| Testing     | neotest — vstest, pytest, vitest, jest *(work in progress)*          |
| AI          | claude-chat.nvim — Claude Code sidebar with IDE + LSP integration    |
| Problems    | trouble.nvim (error list, references), todo-comments                 |
| XAML        | treated as XML: highlighting + lemminx (markup errors, completion, outline); no WPF type info |
| Tasks       | overseer.nvim — runs `.vscode/tasks.json` (dependsOn, problem matchers) |
| Navigation  | telescope.nvim, neo-tree, which-key                                  |
| Git         | gitsigns                                                             |
| Markdown    | render-markdown.nvim — styled in the buffer, `<leader>um` toggles    |
| Misc        | lualine, toggleterm, nvim-autopairs                                  |

Language servers, formatters and debug adapters are installed automatically by
Mason on first launch.

## Requirements

- [Neovim](https://neovim.io) **0.12+**
- [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads), set as the terminal font
- `git`, [ripgrep](https://github.com/BurntSushi/ripgrep), [fd](https://github.com/sharkdp/fd)
- A C compiler (zig or MSVC) and [tree-sitter-cli](https://github.com/tree-sitter/tree-sitter) 0.26.1+ for Treesitter parsers
- [.NET SDK](https://dotnet.microsoft.com) (C#), [Node.js](https://nodejs.org) 23.6+ (TypeScript), Python 3 (Python)

On Windows:

```powershell
winget install Neovim.Neovim BurntSushi.ripgrep.MSVC sharkdp.fd zig.zig tree-sitter.tree-sitter-cli DEVCOM.JetBrainsMonoNerdFont
```

## Install

```powershell
git clone https://github.com/Zurisen/nvim-config.git "$env:LOCALAPPDATA\nvim"
nvim
```

The first launch installs plugins, parsers and Mason tools — give it a minute,
then run `:checkhealth`.

## Layout

```
init.lua            leader key + loads lua/config/*
lua/config/         options, keymaps, autocmds, lazy.nvim bootstrap
lua/plugins/        one file per area; every file is picked up by lazy.nvim
lazy-lock.json      pinned plugin versions (update with :Lazy update)
```

## Key bindings

Leader is `Space`. Press it and wait for which-key to list everything.
For a task-oriented cheat sheet, see [docs/key-actions.md](docs/key-actions.md).

| Keys | Action |
|------|--------|
| `Ctrl+Shift+P` / `Ctrl+P` | Go to file (search bar at the top) |
| `Ctrl+Shift+E` | Switch between the code and the git changes window (from elsewhere: go to the git window) |
| `<leader>gs` | Show / hide the git changes window (left; open by default in a git repo). Moving through it shows each file at its first change |
| `Ctrl+Shift+J` / `Ctrl+Shift+K` | Next / previous git change of the file (also from the git window) |
| `<leader>e` | File explorer popup |
| `<leader>m` | Toggle the methods outline sidebar (aerial) |
| `Ctrl+Shift+I` | Switch between Claude and the window you came from (opens Claude if needed) |
| `<leader>ai` | Toggle the Claude Code sidebar (`<C-h/j/k/l>` move out, `<C-q>` hide) |
| `Alt+K` / `<leader>as` | Insert `@file#10-25` for the selection (or `@file` without one) into Claude's prompt; focus stays in the editor |
| `<leader>af` / `<leader>ac` / `<leader>ar` / `<leader>an` | Claude: add file / continue / resume past session / new conversation |
| `<leader>sf` / `<leader>sg` / `<leader><leader>` | Find files / grep / open buffers |
| `gd`, `K`, `grr`, `gri` | Definition, hover docs, references, implementation |
| `<leader>cr` / `<leader>ca` / `<leader>cf` / `<leader>cd` | Rename / code action / format / line diagnostics |
| `F5` / `Shift+F5` | Debug: start-continue / stop. Offers `.vscode/launch.json` configs plus "Build & launch project" |
| `Ctrl+F5` / `<leader>dR` | Run a `launch.json` config without the debugger |
| `F9` / `F10` / `F11` / `Shift+F11` | Breakpoint / step over / into / out |
| `<leader>d…` | More debug actions (conditional breakpoint, REPL, UI, eval) |
| `<leader>tt` / `<leader>tf` / `<leader>ts` | Run nearest test / file tests / test explorer |
| `<leader>gg` | lazygit in a floating window (`e` on a file opens it in Neovim) |
| `<leader>g…` | Git hunks: preview, reset, blame, diff (changed lines are tinted green) |
| `Ctrl+\` / `<leader>ut` | Toggle terminal / floating terminal |
| `Ctrl+Shift+B` / `<leader>rb` | Run the default build task from `.vscode/tasks.json` (errors become diagnostics) |
| `<leader>rr` / `<leader>rt` / `<leader>rl` | Tasks: pick and run / toggle task list + output / re-run last |
| `<leader>uh` | Toggle inlay hints |
| `<leader>ur` | Redraw and even out window sizes (also automatic on terminal resize) |
| `<leader>xx` / `<leader>xX` / `<leader>xr` / `<leader>xt` | Trouble: all problems / this file / references / TODOs |
| `]T` / `[T` / `<leader>st` | Next / previous TODO / search TODOs |
| `<leader>ha` / `<leader>hh` / `Alt+1…5` | Harpoon: pin file / menu (reorder, remove) / jump to pinned file 1–5 |
| `<leader>ws` / `<leader>wr` / `<leader>wd` | Sessions: find / restore this folder's / delete this folder's |

Completion menu: `Ctrl+n` / `Ctrl+p` to move, `Ctrl+y` to accept.

## Notes

- Edited files are saved automatically when you switch to Claude, a terminal or
  lazygit, or when Neovim loses focus, and files changed on disk (by Claude,
  git, builds) reload within a second. So Claude always edits your latest code
  and its changes show up next to yours, like in VS Code. If a file has unsaved
  edits *and* changes on disk, Neovim asks which version to keep.
- Sessions are saved per folder on exit and restored when you start `nvim`
  (or `nvim .`) there. Sidebars (Claude, explorer, terminals, debugger) are
  closed before saving. Not saved for the home folder or a drive root, or when
  Neovim runs inside another Neovim's terminal.
- Terminals send the same code for `Ctrl+Shift+<key>` and `Ctrl+<key>`. For
  `Ctrl+Shift+P/E/I/B/J/K` to reach Neovim, Windows Terminal sends CSI-u codes
  (`settings.json`; this replaces its own `Ctrl+Shift+P` command palette):
  ```json
  "actions": [
    { "command": { "action": "sendInput", "input": "\u001b[112;6u" }, "id": "User.NvimCtrlShiftP" },
    { "command": { "action": "sendInput", "input": "\u001b[101;6u" }, "id": "User.NvimCtrlShiftE" },
    { "command": { "action": "sendInput", "input": "\u001b[105;6u" }, "id": "User.NvimCtrlShiftI" },
    { "command": { "action": "sendInput", "input": "\u001b[98;6u" }, "id": "User.NvimCtrlShiftB" },
    { "command": { "action": "sendInput", "input": "\u001b[106;6u" }, "id": "User.NvimCtrlShiftJ" },
    { "command": { "action": "sendInput", "input": "\u001b[107;6u" }, "id": "User.NvimCtrlShiftK" }
  ],
  "keybindings": [
    { "id": "User.NvimCtrlShiftP", "keys": "ctrl+shift+p" },
    { "id": "User.NvimCtrlShiftE", "keys": "ctrl+shift+e" },
    { "id": "User.NvimCtrlShiftI", "keys": "ctrl+shift+i" },
    { "id": "User.NvimCtrlShiftB", "keys": "ctrl+shift+b" },
    { "id": "User.NvimCtrlShiftJ", "keys": "ctrl+shift+j" },
    { "id": "User.NvimCtrlShiftK", "keys": "ctrl+shift+k" }
  ]
  ```
- Windows Terminal appearance (frosted-glass terminal area with a solid
  Dracula tab bar; Neovim keeps its solid Dracula background). In `settings.json`: the official
  [Dracula scheme](https://github.com/dracula/windows-terminal) in `schemes`, plus
  ```json
  "theme": "glass",
  "themes": [ { "name": "glass",
                "window": { "applicationTheme": "dark" },
                "tabRow": { "background": "#21222C", "unfocusedBackground": "#21222C" },
                "tab": { "background": "#282A36", "unfocusedBackground": "#00000000" } } ],
  "profiles": { "defaults": { "font": { "face": "JetBrainsMono NF", "size": 11 },
                              "opacity": 50, "useAcrylic": true, "colorScheme": "Dracula",
                              "scrollbarState": "hidden" } }
  ```
  Plus a solid "Neovim" profile in `profiles.list`, so Neovim tabs have no glass
  showing in the margins (Windows Terminal draws whole cells only, and fills
  the padding and leftover pixels with the background):
  ```json
  { "name": "Neovim", "guid": "{643fad59-1cec-4828-b140-fe31de5a5cca}",
    "commandline": "\"C:\\Program Files\\Neovim\\bin\\nvim.exe\" .",
    "startingDirectory": "C:\\Code\\MyApp\\src",
    "icon": "C:\\Program Files\\Neovim\\share\\icons\\hicolor\\128x128\\apps\\nvim.png",
    "opacity": 100, "useAcrylic": false }
  ```
  And in the PowerShell profile (`$PROFILE`), so typing `nvim` in any folder
  opens it in a tab of that profile:
  ```powershell
  function nvim {
      $exe = 'C:\Program Files\Neovim\bin\nvim.exe'
      if (-not $env:WT_SESSION) { & $exe @args; return }
      $dir = $PWD.ProviderPath
      if ($dir.EndsWith('\')) { $dir += '.' }
      $nvimArgs = @($args)
      if ($nvimArgs.Count -eq 0) { $nvimArgs = @('.') }
      wt.exe -w 0 new-tab --profile "Neovim" --startingDirectory $dir $exe @nvimArgs
  }
  ```
- Merge conflicts open in Visual Studio's merge editor (`M` on a conflicted
  file in lazygit, or `git mergetool`), via this global git config:
  ```
  git config --global merge.tool vsdiffmerge
  git config --global mergetool.vsdiffmerge.cmd '"<VS>/Common7/IDE/CommonExtensions/Microsoft/TeamFoundation/Team Explorer/vsDiffMerge.exe" "$REMOTE" "$LOCAL" "$BASE" "$MERGED" //m'
  git config --global mergetool.vsdiffmerge.trustExitCode true
  ```
- C# (roslyn) needs a `.sln`/`.slnx` or `.csproj` in or above the current folder.
- On Windows, netcoredbg only resolves breakpoints in backslash paths;
  `lua/plugins/debug.lua` rewrites them automatically.
