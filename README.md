# ghostty-random-theme

A random [Ghostty](https://ghostty.org) theme on every new terminal session.

Each time you open a new tab, window, or split, a theme is picked at random from Ghostty's 400+ built-in themes and applied instantly via OSC escape sequences. No config files are modified — colors are set in-memory for that session only.

## Why

Someone [asked for this in the Ghostty repo](https://github.com/ghostty-org/ghostty/discussions/3577) and a contributor correctly pointed out that a shell-level solution is the right approach. Here it is.

## Install

### Automatic (recommended)

Clone or download the project anywhere, then run the installer:

```bash
git clone https://github.com/merinids212/ghostty-random-theme.git
cd ghostty-random-theme
./install.sh
```

```
  ✓ copied scripts → ~/.ghostty-random-theme
  ✓ ~/.zshrc: added source line

  → open a new Ghostty window
```

It works out which shell you use, copies the theme scripts to `~/.ghostty-random-theme`, and adds the source line to the correct startup file.

Because the scripts are copied there, **the folder you ran it from can be deleted afterwards** — useful if you downloaded a zip instead of cloning, or moved the project over from another machine. Running the installer again is safe and refreshes the installed copy, so it also serves as the update command.

If the execute bit didn't survive the trip — some zip tools drop it — run `bash install.sh` instead.

Where the source line goes:

- **zsh** → `$ZDOTDIR/.zshrc` when `ZDOTDIR` is set, otherwise `~/.zshrc`
- **bash** → `~/.bashrc`. If `~/.bash_profile` exists but doesn't source `~/.bashrc`, the installer adds that link too — without it, macOS login shells never read `.bashrc` and nothing would happen

Options:

| Flag | Effect |
| --- | --- |
| `--shell zsh` / `--shell bash` | Target a shell instead of guessing from `$SHELL` |
| `--rc PATH` | Write the source line to a startup file you name |
| `--help` | Show usage |

Only zsh and bash are supported; the installer exits with a message for anything else rather than writing a file that would never be read.

### Manual

Two steps. The second is what makes the theme change on every new session — without it, nothing happens.

> **Don't just paste the `source` line into a running terminal.** That applies one theme to that one window and is forgotten the moment you close it. The line has to live in your startup file.

#### zsh (macOS default)

**1. Clone:**

```bash
git clone https://github.com/merinids212/ghostty-random-theme.git ~/.ghostty-random-theme
```

**2. Add it to `~/.zshrc`:**

```bash
grep -q ghostty-random-theme ~/.zshrc 2>/dev/null || printf '\nsource ~/.ghostty-random-theme/random-theme.zsh\n' >> ~/.zshrc
```

#### bash (most Linux distros)

**1. Clone:**

```bash
git clone https://github.com/merinids212/ghostty-random-theme.git ~/.ghostty-random-theme
```

**2. Add it to `~/.bashrc`:**

```bash
grep -q ghostty-random-theme ~/.bashrc 2>/dev/null || printf '\nsource ~/.ghostty-random-theme/random-theme.bash\n' >> ~/.bashrc
```

Step 2 is safe to run more than once — it checks for the line before adding it, so re-running (or re-following this README later) won't leave you with duplicates. It also won't mangle a startup file that lacks a trailing newline.

Use `.zshrc` / `.bashrc` specifically — not `.zshenv`, `.zprofile`, or `.bash_profile`. The script is meant for interactive shells only; sourcing it elsewhere leaks escape sequences into scripts and non-interactive sessions.

On macOS with bash, also check that `~/.bash_profile` sources `~/.bashrc` — login shells read `.bash_profile`, and if it doesn't pull in `.bashrc` your new line never runs. The automatic installer handles this for you.

### Verify

Open a **brand new** Ghostty window. You should see the theme name at the top of the session:

```
Theme: TokyoNight Night
```

Open one more — it should report a different theme. If it does, you're done.

Windows that were already open keep their current colors. The script runs at shell startup, so it can't retroactively affect a session that has already started.

## Troubleshooting

**No `Theme:` line appears in new windows.**

Work through these in order:

```bash
# 1. Is the line actually in your startup file? Should print the source line.
grep random-theme ~/.zshrc     # or ~/.bashrc

# 2. Are you in Ghostty? Should print: ghostty
echo "$TERM_PROGRAM"

# 3. Can the script find the themes? Should print a path, and list 400+ files.
echo "$GHOSTTY_RESOURCES_DIR"
ls "$GHOSTTY_RESOURCES_DIR/themes" | wc -l
```

If step 1 prints nothing, the `source` line never got saved. Re-run `./install.sh`, or redo step 2 of the manual install. This is by far the most common cause.

If step 2 prints something other than `ghostty`, the script exits early on purpose; you're in a different terminal.

If step 3 is empty, your Ghostty install puts resources somewhere unusual. Set the directory yourself before the `source` line in your startup file:

```bash
export GHOSTTY_RESOURCES_DIR=/path/to/ghostty
```

**Every window shows the same theme.** Confirm the script is being re-run rather than a theme being set in your Ghostty config — check `~/.config/ghostty/config` for a `theme =` line and remove it. A config theme is applied by Ghostty itself on every window and isn't what this script does.

**Prompt frameworks that dislike startup output.** The script prints the theme name, which trips warnings in setups that forbid output during init (for example Powerlevel10k's instant prompt). Either source the script *before* the instant-prompt block, or delete the `echo "Theme: $_theme"` line at the bottom of the script.

## How it works

On shell startup, the script:

1. Checks if you're running inside Ghostty (`TERM_PROGRAM`)
2. Finds the built-in themes directory via `GHOSTTY_RESOURCES_DIR` (set by Ghostty on all platforms), with fallbacks for standard install paths
3. Picks one at random using bash/zsh built-in `$RANDOM` — no external dependencies
4. Parses the theme file and applies colors via [OSC escape sequences](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html)
5. Prints the theme name so you know what you got

Your Ghostty config file is never touched. Each session gets its own random theme independently.

## Curating themes

If 400+ themes is too chaotic, you can limit it to a favorites list.

Edit the copy the installer put in `~/.ghostty-random-theme`. Find the block under the `# Pick a random theme` comment — the lines that glob the themes directory and index into it — and replace just those with a hardcoded array. Leave the themes-directory detection above it alone.

Note that re-running `./install.sh` overwrites these files, so keep your edited version somewhere if you plan to reinstall.

**zsh** — in `random-theme.zsh`:

```zsh
# Pick a random theme (favorites only)
_favorites=("TokyoNight Night" "Catppuccin Mocha" "Dracula" "Gruvbox Dark")
_theme="${_favorites[RANDOM % $#_favorites + 1]}"
_theme_file="$_ghostty_themes_dir/$_theme"
```

**bash** — in `random-theme.bash`:

```bash
# Pick a random theme (favorites only)
_favorites=("TokyoNight Night" "Catppuccin Mocha" "Dracula" "Gruvbox Dark")
_theme="${_favorites[RANDOM % ${#_favorites[@]}]}"
_theme_file="$_ghostty_themes_dir/$_theme"
```

## Development

The installer has a test suite. It runs `install.sh` against throwaway `$HOME`
directories, so it never touches your real startup files:

```bash
./test-install.sh
```

## License

MIT
