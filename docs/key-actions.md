# Key actions

The most important actions in this config and their keys. `Space` is the
leader key: press it and wait, and which-key lists everything that follows.
`Space s k` searches every keymap.

## Essentials

| Key | Action |
|---|---|
| `Ctrl+Shift+E` | Switch between the code and the git changes window. From anywhere else (Claude, terminals, popups) it goes to the git window, reopening it if closed |
| `Ctrl+Shift+I` | Switch between Claude and the window you came from (git window or code) |
| `Ctrl+Shift+J` / `Ctrl+Shift+K` | Next / previous git change in the file (also from the git window) |
| `Space g s` | Show / hide the git changes window (open by default) |
| `Space e` | File explorer popup |
| `Ctrl+Shift+P` (or `Ctrl+P`) | Go to file. Always opens in the code window, even from Claude or the git window. Also finds git-ignored files (e.g. notes in `.claude/docs`), but not build output |
| `Ctrl+Shift+B` | Build (the default build task in `.vscode/tasks.json`) |

## Git changes window (left side)

Opens automatically when you start Neovim in a git repository (`nvim` or
`nvim .`) and stays open until you close it with `Space g s`. It lists only the
files with changes and refreshes when files change (saves, Claude, git) and
when you come back from Claude or a terminal.

Folders that only contain one folder are merged, and a merged chain shows only
its last two folders (e.g. `Views/Dialogs` instead of
`src/MyApp/.../Views/Dialogs`). File names are never cut: if the
selected file's line is wider than the window, the window scrolls sideways to
show the name.

| Key | Action |
|---|---|
| `Ctrl+Shift+E` | Into the git window / back to the code |
| `Ctrl+Shift+I` | To Claude, and back to the git window with the same key |
| `j` / `k` | Move through the files: each one is shown in the code window right away, at its first change |
| `Ctrl+Shift+J` / `Ctrl+Shift+K` | Jump the code to the next / previous change of that file, without leaving the git window |
| `Enter` | Move into the file |
| `ga` / `gu` / `A` | Stage / unstage the file / stage all |
| `gr` / `gc` | Revert the file / commit |
| `Tab` | Mark several files, then apply one action (stage, revert...) to all |
| `Space …` | Leader keys work here too (e.g. `Space g s` closes the window) |

Changed lines are tinted green in the code (added and modified lines); the
band on the left marks additions (green), modifications and deletions (red).

## Moving between files

| Key | Action |
|---|---|
| `Space Space` | List open files and switch between them, like tabs |
| `Space s g` | Search text in the whole project |
| `Space s .` | Recent files |
| `Space /` | Search in the current file |
| `Ctrl+o` / `Tab` | Jump back / forward through where you've been |
| `Ctrl+h/j/k/l` | Move between split windows (also from the Claude sidebar) |

In the explorer popup (`Space e`): `Enter` opens a file (and closes the popup),
`a` adds a file or folder, `r` renames, `d` deletes, `?` shows all of its keys,
`q` closes it.

## Code navigation (LSP)

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `grr` | List references |
| `gri` | Go to implementation |
| `grt` | Go to type definition |
| `K` | Documentation / type info under the cursor |
| `Ctrl+S` (insert mode) | Show the signature of the method you're calling |
| `Space m` | Methods outline sidebar: opens and moves into it. `j`/`k` scroll the code to each method as you go, `Enter` moves into the code there; press again to close it and return to the code |
| `gO` | Outline of the current file as a list |
| `Space s s` / `Space s S` | Search symbols in this file / the whole workspace |
| `grn` (or `Space c r`) | Rename symbol everywhere |
| `gra` (or `Space c a`) | Code actions (quick fixes, refactorings) |
| `Space c f` | Format the file |
| `]d` / `[d` | Next / previous error or warning |
| `Space c d` | Show the error under the cursor |
| `Space s d` | Search all errors and warnings |
| `Space u h` | Toggle inlay hints (inferred types, parameter names) |
| `gcc` | Comment / uncomment the line (`gc` on a selection) |

### Finding references

Put the cursor on the method, variable, class or property name:

| Key | What you get |
|---|---|
| `Space x r` | **Recommended.** Trouble panel with every reference, grouped by file. `j`/`k` move, `Enter` jumps, `q` closes |
| `grr` | The same references in the plain quickfix list at the bottom. `Enter` jumps; close with `:cclose` |
| `Space s w` | Text search for the word under the cursor across the project |
| `gd` / `gri` | Go to the definition / the implementations (interfaces, abstract methods) |
| `grn` (or `Space c r`) | Rename it everywhere it's used |
| `Ctrl+o` | Jump back to where you were |

`Space x r`, `grr` and rename come from the C# language server (roslyn): exact,
code-only results, but it only knows C#, so **usages in XAML are missed**
(`{Binding PropertyName}`, `Click="OnSave"`, styles). `Space s w` finds those
too, along with matches in comments and strings. Claude can also answer "where
is X used?" (it uses roslyn's references and can search XAML).

## Problems, references and TODOs (Trouble)

A clickable panel, like Visual Studio's Error List. `Enter` on an entry jumps to
it; `q` closes the panel.

| Key | Action |
|---|---|
| `Space x x` | All errors and warnings: open files plus build errors from `Ctrl+Shift+B` |
| `Space x X` | Errors and warnings in this file only |
| `Space x r` | References of the symbol under the cursor |
| `Space x t` | All TODO / FIXME / HACK comments in the project |
| `Space x q` / `Space x l` | Quickfix / location list |

**TODO comments** (`TODO`, `FIX`/`FIXME`/`BUG`, `HACK`, `WARN`, `PERF`, `NOTE`,
`TEST`) are highlighted in comments, with or without a colon.

| Key | Action |
|---|---|
| `]T` / `[T` | Next / previous TODO in the file |
| `Space s t` | Search TODOs across the project |
| `Space x t` | TODO list panel |

## Claude

| Key | Action |
|---|---|
| `Space a i` | Toggle the Claude sidebar |
| `Ctrl+Shift+I` | Switch between Claude and the window you came from (opens Claude if needed) |
| `Alt+K` (or `Space a s`) | Reference the selection in Claude's prompt (see below) |
| `Space a f` | Add the current file to the conversation |
| `Space a c` / `Space a r` | Continue the last conversation / pick a past one to resume |
| `Space a n` | New conversation |
| In the sidebar: `Ctrl+h` / `Ctrl+l` | Move to the window on the left / right (Claude keeps running) |
| In the sidebar: `Ctrl+J` | New line in your message, without sending it. `\` then `Enter` also works |
| In the sidebar: `Ctrl+G` | Write the message in a full editor (Claude Code's own shortcut); save and close it to return |
| In the sidebar: `Home` | Fullscreen Claude (covers the whole editor); `Home` again goes back to the sidebar |
| In the sidebar: `PageUp` / `PageDown` | Scroll the conversation (see below) |
| In the sidebar: `Ctrl+q` | Hide it |

**Fullscreen:** `Home` shows the same conversation over the whole editor.
`Home` again, or leaving it any other way (`Ctrl+Shift+I`, `Ctrl+P`, a diff
opening), returns to the sidebar layout. Claude's own "start of line" key is
`Ctrl+A`, since `Home` is taken.

**Scrolling the conversation:** Claude Code draws the conversation itself, so
it does the scrolling (Neovim's buffer only holds the visible screen):

| Key | Action |
|---|---|
| Mouse wheel | A few lines up / down |
| `PageUp` / `PageDown` | Half a screen up / down |
| `Ctrl+Home` / `Ctrl+End` | Start of the conversation / back to the latest message |
| `Ctrl+O` | Transcript view (the whole conversation, with search); `Ctrl+O` again to leave |

**Referencing code (`Alt+K`):**

1. Select lines (`V` then `j`/`k`) and press `Alt+K`. Claude's prompt gets
   `@UnitTest1.cs#4-12`, and you stay in the editor.
2. Select more lines, in this file or others, and press `Alt+K` again. Each one
   adds another reference.
3. Press `Ctrl+Shift+I` and type your question after the references, for
   example "Compare these two methods and merge them".

For a quick question about one block, select it and press `Ctrl+Shift+I`
directly: Claude sees the live selection. Proposed edits appear as a
side-by-side diff; approve or reject them in the sidebar.

## Git

| Key | Action |
|---|---|
| `Space g g` | Open lazygit (press again or `q` to close) |
| `Space g s` | Show / hide the git changes window (see "Git changes window" above) |
| `]h` / `[h` | Next / previous changed block (hunk) in the file |
| `Space g p` | Preview the change under the cursor |
| `Space g r` | Undo the change under the cursor |
| `Space g b` | Who changed this line (blame) |
| `Space g d` | Side-by-side diff of the file vs the staged version; press again to go back to the normal file |

**Side-by-side diff (`Space g d`):** the old version is on the left (read-only),
your file on the right.

| Key | Action |
|---|---|
| `]c` / `[c` | Next / previous change |
| `do` | On a change in your file: take the old version back (revert that block) |
| `Space g d` | Close the diff and return to the normal file |

Opening a file from the explorer or the git window closes any open diff first, so
files always open normally.

**Inside lazygit:**

| Key | Action |
|---|---|
| `1`…`5` | Jump to panel: status, files, branches, commits, stash |
| `Space` | Stage / unstage the file (on a branch: check it out) |
| `a` | Stage / unstage all files |
| `Enter` | Open the file's diff to stage individual lines or hunks |
| `c` | Commit the staged changes |
| `A` | Amend the last commit |
| `d` | Discard changes to the file (asks first) |
| `e` | Open the file in Neovim |
| `s` | Stash all changes |
| `P` / `p` / `f` | Push / pull / fetch |
| `n` (branches panel) | New branch |
| `M` (branches panel) | Merge the selected branch into the current one |
| `M` (conflicted file) | Merge options → "Open external merge tool" opens Visual Studio's merge editor (takes ~20-30 s to start) |
| `z` | Undo the last git action |
| `[` / `]` | Previous / next tab within a panel |
| `?` | All keys for the current panel |
| `Esc` / `q` | Back / quit lazygit |

## Building and running

| Key | Action |
|---|---|
| `Ctrl+Shift+B` (or `Space r b`) | Build: runs the default build task, opens the task output |
| `Space r r` | Pick and run any task from `.vscode/tasks.json` |
| `Space r t` | Show / hide the task list and output |
| `Space r l` | Re-run the last task |
| `Ctrl+F5` (or `Space d R`) | Run a `launch.json` configuration without the debugger |

Build errors appear on the right lines; `Space s d` lists them.

## Debugging

**With the debugger: `F5`**

1. Set breakpoints with `F9` (or `Space d b`).
2. Press `F5` and choose a configuration from your `launch.json` (e.g. "Launch MyApp") from
   the list. Build first with `Ctrl+Shift+B`: `F5` doesn't build.
3. The debug panels (variables, call stack, watches, console) open
   automatically when it starts.

**Controls while debugging:**

| Key | Action |
|---|---|
| `F10` / `F11` / `Shift+F11` | Step over / into / out |
| `F5` | Continue |
| `Space d e` | Evaluate the expression under the cursor |
| `Space d B` | Conditional breakpoint |
| `Space d C` | Run to the cursor |
| `Space d l` | Repeat the last launch without the list |
| `Space d u` | Show / hide the debug panels |
| `Shift+F5` | Stop the app |

## Tests

| Key | Action |
|---|---|
| `Space t t` | Run the test under the cursor |
| `Space t f` | Run all tests in the file |
| `Space t A` | Run all tests |
| `Space t d` | Debug the test under the cursor |
| `Space t l` | Re-run the last test |
| `Space t s` | Test explorer |
| `Space t o` | Show the output of the test under the cursor |
| `]t` / `[t` | Next / previous failed test |

## Harpoon (pinned files, kept per project)

| Key | Action |
|---|---|
| `Space h a` | Pin the current file |
| `Alt+1` … `Alt+5` | Jump straight to pinned file 1–5 |
| `Space h h` | Open the list |
| `Space h p` / `Space h n` | Previous / next pinned file |

In the list you can reorder by moving lines (`dd` then `p`), remove a pin with
`dd`, and press `Enter` to open a file. Changes are saved when you close it.

## Sessions

Open files and splits are saved per folder when you quit, and restored when you
start `nvim` (or `nvim .`) in the same folder.

| Key | Action |
|---|---|
| `Space w s` | Find and switch to a saved session |
| `Space w r` | Restore this folder's session (e.g. after `nvim SomeFile.cs`) |
| `Space w d` | Delete this folder's session |

## Terminal

| Key | Action |
|---|---|
| `Ctrl+\` | Toggle the bottom terminal |
| `Space u t` / `Space u v` | Floating / vertical terminal |
| `Esc Esc` | Leave terminal mode (to scroll or copy) |

## Editing

| Key | Action |
|---|---|
| `Ctrl+n` / `Ctrl+p` | Move in the completion menu |
| `Ctrl+y` | Accept the completion |
| `Ctrl+Space` / `Ctrl+e` | Open / close the completion menu |
| `Esc` | Clear search highlighting (normal mode) |

## Markdown

`.md` files are shown styled: headings, bold, lists, checkboxes, tables and
code blocks. The line under the cursor, and the whole file while typing, show
the raw text so you can edit it.

| Key | Action |
|---|---|
| `Space u m` | Switch between styled and raw markdown |

## Refreshing the screen

Windows are re-balanced automatically when the terminal is resized (the Claude
sidebar keeps its width). From lightest to heaviest:

| Key | Action |
|---|---|
| `Space u r` | Redraw the screen and even out window sizes |
| `Ctrl+W` then `=` | Only even out window sizes |
| `:restart` | Restart Neovim in place; files and splits come back via the session. The Claude conversation ends: continue it with `Space a c` |

(`Ctrl+L` is used for moving to the right-hand window, so it doesn't redraw.)
