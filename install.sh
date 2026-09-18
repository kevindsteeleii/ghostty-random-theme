## Install

### zsh (macOS default)
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

# add to your .zshrc
source ~/.ghostty-random-theme/random-theme.zsh
```

### bash (most Linux distros)
**2. Add it to `~/.zshrc`:**

```bash
grep -q ghostty-random-theme ~/.zshrc 2>/dev/null || printf '\nsource ~/.ghostty-random-theme/random-theme.zsh\n' >> ~/.zshrc
```

#### bash (most Linux distros)

**1. Clone:**

```bash
git clone https://github.com/merinids212/ghostty-random-theme.git ~/.ghostty-random-theme

# add to your .bashrc
source ~/.ghostty-random-theme/random-theme.bash
```

Open a new terminal. That's it.
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

If 400+ themes is too chaotic, you can limit it to a favorites list.

In your shell's script, find the "Pick a random theme" section and replace it with a hardcoded array:
Edit the copy the installer put in `~/.ghostty-random-theme`. Find the block under the `# Pick a random theme` comment — the lines that glob the themes directory and index into it — and replace just those with a hardcoded array. Leave the themes-directory detection above it alone.

**zsh** — replace lines 14–20 in `random-theme.zsh`:
Note that re-running `./install.sh` overwrites these files, so keep your edited version somewhere if you plan to reinstall.

**zsh** — in `random-theme.zsh`:

```zsh
# Pick a random theme (favorites only)
```

**bash** — replace lines 23–28 in `random-theme.bash`:
**bash** — in `random-theme.bash`:

```bash
# Pick a random theme (favorites only)
```

## Development

The installer has a test suite. It runs `install.sh` against throwaway `$HOME`
directories, so it never touches your real startup files:

```bash
./test-install.sh
```

## License

MIT
#!/usr/bin/env bash
# Installer for ghostty-random-theme.
#
# Copies the theme scripts to ~/.ghostty-random-theme and adds a source line
# to your shell's startup file. Safe to run more than once.
#
#   ./install.sh                 # detect shell from $SHELL
#   ./install.sh --shell bash    # force a shell
#   ./install.sh --rc PATH       # write to a specific startup file
#
# https://github.com/merinids212/ghostty-random-theme

set -euo pipefail

DEST_NAME=".ghostty-random-theme"
MARKER="ghostty-random-theme"
SCRIPTS=(random-theme.zsh random-theme.bash)

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

green() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
dim() { printf '  \033[2m·\033[0m \033[2m%s\033[0m\n' "$1"; }
warn() { printf '  \033[33m⚠\033[0m %s\n' "$1"; }
die() {
  printf '\033[31merror:\033[0m %s\n' "$1" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Install ghostty-random-theme into your shell startup file.

Usage: ./install.sh [options]

Options:
  --shell zsh|bash   Target a specific shell (default: detected from $SHELL)
  --rc PATH          Write the source line to PATH instead of the default
                     startup file for the detected shell
  -h, --help         Show this help

The theme scripts are copied to ~/.ghostty-random-theme, so the directory you
run this from can be deleted afterwards. Re-running updates that copy.
EOF
}

# --- arguments --------------------------------------------------------------

shell_opt=""
rc_opt=""

while [ $# -gt 0 ]; do
  case "$1" in
    --shell)
      [ $# -ge 2 ] || die "--shell needs a value (zsh or bash)"
      shell_opt="$2"
      shift 2
      ;;
    --rc)
      [ $# -ge 2 ] || die "--rc needs a path"
      rc_opt="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1 (try --help)"
      ;;
  esac
done

# --- which shell ------------------------------------------------------------

target_shell="${shell_opt:-$(basename "${SHELL:-}")}"

case "$target_shell" in
  zsh | bash) ;;
  "") die "could not detect your shell. Pass --shell zsh or --shell bash." ;;
  *)
    die "unsupported shell: $target_shell
This project ships zsh and bash scripts only. If $target_shell can source a
bash-compatible file, use: ./install.sh --shell bash --rc <your rc file>"
    ;;
esac

echo
echo "ghostty-random-theme"
echo

# --- copy the scripts into place --------------------------------------------

dest_dir="$HOME/$DEST_NAME"

if [ "$SELF_DIR" = "$dest_dir" ]; then
  dim "already installed in place: ~/$DEST_NAME"
else
  mkdir -p "$dest_dir"
  for script in "${SCRIPTS[@]}"; do
    if [ -f "$SELF_DIR/$script" ]; then
      cp "$SELF_DIR/$script" "$dest_dir/$script"
    fi
  done
  green "copied scripts → ~/$DEST_NAME"
fi

theme_script="$dest_dir/random-theme.$target_shell"
[ -f "$theme_script" ] || die "missing $theme_script — run this from the project directory"

# --- pick the startup file --------------------------------------------------

if [ -n "$rc_opt" ]; then
  rc_file="$rc_opt"
elif [ "$target_shell" = "zsh" ]; then
  rc_file="${ZDOTDIR:-$HOME}/.zshrc"
else
  rc_file="$HOME/.bashrc"
fi

# --- add the source line ----------------------------------------------------

source_line="source ~/$DEST_NAME/random-theme.$target_shell"

pretty() { printf '%s' "${1/#$HOME/~}"; }

if grep -qF -- "$MARKER" "$rc_file" 2>/dev/null; then
  dim "$(pretty "$rc_file"): already has the source line"
else
  mkdir -p "$(dirname "$rc_file")"
  # leading newline guards against a startup file with no trailing newline
  printf '\n# %s\n%s\n' "$MARKER" "$source_line" >>"$rc_file"
  green "$(pretty "$rc_file"): added source line"
fi

# --- bash only: make sure login shells reach .bashrc ------------------------

if [ "$target_shell" = "bash" ] && [ -z "$rc_opt" ]; then
  profile="$HOME/.bash_profile"
  if [ -f "$profile" ]; then
    if grep -qE '(^|[[:space:]])(\.|source)[[:space:]]+"?(\$HOME|~)/\.bashrc' "$profile"; then
      dim "$(pretty "$profile"): already sources .bashrc"
    else
      printf '\n# %s: load .bashrc for login shells\n[ -f ~/.bashrc ] && . ~/.bashrc\n' \
        "$MARKER" >>"$profile"
      green "$(pretty "$profile"): now sources .bashrc"
    fi
  fi
fi

# --- sanity check: can the script find any themes? --------------------------

themes_found=""
for candidate in \
  "${GHOSTTY_RESOURCES_DIR:-}/themes" \
  "/Applications/Ghostty.app/Contents/Resources/ghostty/themes" \
  "/usr/share/ghostty/themes" \
  "${XDG_DATA_HOME:-$HOME/.local/share}/ghostty/themes"; do
  if [ -d "$candidate" ]; then
    themes_found="$candidate"
    break
  fi
done

if [ -z "$themes_found" ]; then
  warn "no Ghostty themes directory found yet"
  printf '      That is fine if Ghostty is not installed on this machine yet.\n'
  printf '      The script exits quietly until it can find one.\n'
fi

echo
printf '  → open a new Ghostty window\n'
if [ "$SELF_DIR" != "$dest_dir" ]; then
  printf '\033[2m    (%s is no longer needed)\033[0m\n' "$(pretty "$SELF_DIR")"
fi
echo

#!/usr/bin/env bash
# Tests for install.sh
#
# Every test runs the installer against a throwaway $HOME, so nothing here
# touches your real startup files. Run with: ./test-install.sh

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL="$REPO/install.sh"

SOURCE_LINE_ZSH='source ~/.ghostty-random-theme/random-theme.zsh'
SOURCE_LINE_BASH='source ~/.ghostty-random-theme/random-theme.bash'
CHAIN_LINE='[ -f ~/.bashrc ] && . ~/.bashrc'

pass=0
fail=0

ok() { printf '  \033[32m✓\033[0m %s\n' "$1"; pass=$((pass + 1)); }
no() {
  printf '  \033[31m✗\033[0m %s\n' "$1"
  printf '      %s\n' "$2"
  fail=$((fail + 1))
}

# --- assertions -------------------------------------------------------------

# assert_count <file> <fixed-string> <expected> <label>
assert_count() {
  local file=$1 needle=$2 want=$3 label=$4 got
  got=$(grep -cF -- "$needle" "$file" 2>/dev/null)
  [ -z "$got" ] && got=0
  if [ "$got" -eq "$want" ]; then
    ok "$label"
  else
    no "$label" "want $want occurrence(s) of '$needle' in ${file#"$SANDBOX"}, got $got"
  fi
}

assert_file() {
  local file=$1 label=$2
  if [ -f "$file" ]; then ok "$label"; else no "$label" "expected file to exist: $file"; fi
}

assert_no_file() {
  local file=$1 label=$2
  if [ ! -e "$file" ]; then ok "$label"; else no "$label" "expected file NOT to exist: $file"; fi
}

assert_absent() {
  local file=$1 needle=$2 label=$3
  if grep -qF -- "$needle" "$file" 2>/dev/null; then
    no "$label" "did not expect '$needle' in $file"
  else
    ok "$label"
  fi
}

assert_status() {
  local got=$1 want=$2 label=$3
  if [ "$got" -eq "$want" ]; then ok "$label"; else no "$label" "want exit $want, got $got"; fi
}

# --- harness ----------------------------------------------------------------

SANDBOX=""
new_home() {
  SANDBOX=$(mktemp -d)
  HOME_DIR="$SANDBOX/home"
  mkdir -p "$HOME_DIR"
}

cleanup() { [ -n "$SANDBOX" ] && rm -rf "$SANDBOX"; }
trap cleanup EXIT

# Simulate an unzipped copy of the project at an arbitrary path.
fake_unzip() {
  local dest=$1
  mkdir -p "$dest"
  cp "$REPO/install.sh" "$REPO/random-theme.zsh" "$REPO/random-theme.bash" "$dest/"
}

# run_install <installer-path> [args...]  — uses $HOME_DIR and $TEST_SHELL
run_install() {
  local installer=$1
  shift
  env -u ZDOTDIR -u TERM_PROGRAM -u GHOSTTY_RESOURCES_DIR \
    HOME="$HOME_DIR" \
    SHELL="${TEST_SHELL:-/bin/zsh}" \
    PATH="$PATH" \
    bash "$installer" "$@" >"$SANDBOX/out" 2>&1
}

# Same, but with ZDOTDIR exported.
run_install_zdotdir() {
  local installer=$1 zdotdir=$2
  shift 2
  env -u TERM_PROGRAM -u GHOSTTY_RESOURCES_DIR \
    HOME="$HOME_DIR" \
    ZDOTDIR="$zdotdir" \
    SHELL="${TEST_SHELL:-/bin/zsh}" \
    PATH="$PATH" \
    bash "$installer" "$@" >"$SANDBOX/out" 2>&1
}

# --- tests ------------------------------------------------------------------

test_zsh_fresh() {
  new_home
  TEST_SHELL=/bin/zsh run_install "$INSTALL"
  assert_status $? 0 "exits 0 on a fresh machine"
  assert_file "$HOME_DIR/.zshrc" "creates ~/.zshrc when absent"
  assert_count "$HOME_DIR/.zshrc" "$SOURCE_LINE_ZSH" 1 "writes the zsh source line"
  cleanup
}

test_zsh_idempotent() {
  new_home
  TEST_SHELL=/bin/zsh run_install "$INSTALL"
  TEST_SHELL=/bin/zsh run_install "$INSTALL"
  TEST_SHELL=/bin/zsh run_install "$INSTALL"
  assert_status $? 0 "exits 0 when already installed"
  assert_count "$HOME_DIR/.zshrc" "$SOURCE_LINE_ZSH" 1 "three runs leave exactly one source line"
  cleanup
}

test_zsh_no_trailing_newline() {
  new_home
  printf 'export FOO=1' >"$HOME_DIR/.zshrc" # deliberately unterminated
  TEST_SHELL=/bin/zsh run_install "$INSTALL"
  assert_count "$HOME_DIR/.zshrc" 'export FOO=1' 1 "preserves an rc file with no trailing newline"
  assert_count "$HOME_DIR/.zshrc" "$SOURCE_LINE_ZSH" 1 "appends cleanly to an unterminated rc file"
  cleanup
}

test_zsh_preserves_existing_content() {
  new_home
  printf 'export FOO=1\nalias ll="ls -la"\n' >"$HOME_DIR/.zshrc"
  TEST_SHELL=/bin/zsh run_install "$INSTALL"
  assert_count "$HOME_DIR/.zshrc" 'export FOO=1' 1 "leaves existing exports alone"
  assert_count "$HOME_DIR/.zshrc" 'alias ll="ls -la"' 1 "leaves existing aliases alone"
  cleanup
}

test_zdotdir() {
  new_home
  local zdd="$HOME_DIR/.config/zsh"
  mkdir -p "$zdd"
  TEST_SHELL=/bin/zsh run_install_zdotdir "$INSTALL" "$zdd"
  assert_status $? 0 "exits 0 with ZDOTDIR set"
  assert_count "$zdd/.zshrc" "$SOURCE_LINE_ZSH" 1 "honours ZDOTDIR for the rc location"
  assert_no_file "$HOME_DIR/.zshrc" "does not touch ~/.zshrc when ZDOTDIR is set"
  cleanup
}

test_bash_no_profile() {
  new_home
  TEST_SHELL=/bin/bash run_install "$INSTALL"
  assert_status $? 0 "exits 0 for bash"
  assert_count "$HOME_DIR/.bashrc" "$SOURCE_LINE_BASH" 1 "writes the bash source line to ~/.bashrc"
  assert_no_file "$HOME_DIR/.bash_profile" "does not invent a .bash_profile that wasn't there"
  cleanup
}

test_bash_profile_needs_chain() {
  new_home
  printf 'export PATH="$HOME/bin:$PATH"\n' >"$HOME_DIR/.bash_profile"
  TEST_SHELL=/bin/bash run_install "$INSTALL"
  assert_count "$HOME_DIR/.bashrc" "$SOURCE_LINE_BASH" 1 "source line goes in .bashrc, not .bash_profile"
  assert_count "$HOME_DIR/.bash_profile" "$CHAIN_LINE" 1 "chains .bashrc from an unchained .bash_profile"
  assert_absent "$HOME_DIR/.bash_profile" "$SOURCE_LINE_BASH" "does not duplicate the source line into .bash_profile"
  cleanup
}

test_bash_profile_already_chained_dot_home() {
  new_home
  printf 'export PATH="$HOME/bin:$PATH"\n. "$HOME/.bashrc"\n' >"$HOME_DIR/.bash_profile"
  TEST_SHELL=/bin/bash run_install "$INSTALL"
  assert_count "$HOME_DIR/.bashrc" "$SOURCE_LINE_BASH" 1 "still installs the source line"
  assert_absent "$HOME_DIR/.bash_profile" "$CHAIN_LINE" 'detects an existing `. "$HOME/.bashrc"` chain'
  cleanup
}

test_bash_profile_already_chained_source_tilde() {
  new_home
  printf 'source ~/.bashrc\n' >"$HOME_DIR/.bash_profile"
  TEST_SHELL=/bin/bash run_install "$INSTALL"
  assert_count "$HOME_DIR/.bash_profile" 'source ~/.bashrc' 1 'detects an existing `source ~/.bashrc` chain'
  assert_absent "$HOME_DIR/.bash_profile" "$CHAIN_LINE" "does not add a second chain line"
  cleanup
}

test_bash_chain_idempotent() {
  new_home
  printf 'export PATH="$HOME/bin:$PATH"\n' >"$HOME_DIR/.bash_profile"
  TEST_SHELL=/bin/bash run_install "$INSTALL"
  TEST_SHELL=/bin/bash run_install "$INSTALL"
  assert_count "$HOME_DIR/.bash_profile" "$CHAIN_LINE" 1 "re-running adds only one chain line"
  cleanup
}

test_copies_from_elsewhere() {
  new_home
  local unzipped="$SANDBOX/Downloads/ghostty-random-theme"
  fake_unzip "$unzipped"
  TEST_SHELL=/bin/zsh run_install "$unzipped/install.sh"
  assert_status $? 0 "exits 0 when run from an unrelated directory"
  assert_file "$HOME_DIR/.ghostty-random-theme/random-theme.zsh" "copies the zsh script to ~/.ghostty-random-theme"
  assert_file "$HOME_DIR/.ghostty-random-theme/random-theme.bash" "copies the bash script to ~/.ghostty-random-theme"
  cleanup
}

test_rc_line_is_tilde_not_absolute() {
  new_home
  local unzipped="$SANDBOX/Downloads/ghostty-random-theme"
  fake_unzip "$unzipped"
  TEST_SHELL=/bin/zsh run_install "$unzipped/install.sh"
  assert_count "$HOME_DIR/.zshrc" "$SOURCE_LINE_ZSH" 1 "rc line uses the ~ form"
  assert_absent "$HOME_DIR/.zshrc" "$unzipped" "rc line does not hardcode the source directory"
  cleanup
}

test_survives_source_deletion() {
  new_home
  local unzipped="$SANDBOX/Downloads/ghostty-random-theme"
  fake_unzip "$unzipped"
  TEST_SHELL=/bin/zsh run_install "$unzipped/install.sh"
  rm -rf "$unzipped" # the whole point: throw away the unzipped folder
  assert_file "$HOME_DIR/.ghostty-random-theme/random-theme.zsh" "installed script outlives the source folder"
  assert_count "$HOME_DIR/.ghostty-random-theme/random-theme.zsh" 'TERM_PROGRAM' 1 "copied script still has its content"
  cleanup
}

test_run_from_canonical_dir() {
  new_home
  local canonical="$HOME_DIR/.ghostty-random-theme"
  fake_unzip "$canonical"
  # sentinel proves the installer didn't copy the file over itself
  printf '\n# sentinel\n' >>"$canonical/random-theme.zsh"
  TEST_SHELL=/bin/zsh run_install "$canonical/install.sh"
  assert_status $? 0 "exits 0 when already running from ~/.ghostty-random-theme"
  assert_count "$canonical/random-theme.zsh" '# sentinel' 1 "skips the copy when source is the destination"
  assert_count "$HOME_DIR/.zshrc" "$SOURCE_LINE_ZSH" 1 "still wires up the rc file"
  cleanup
}

test_reinstall_updates_copy() {
  new_home
  local unzipped="$SANDBOX/Downloads/ghostty-random-theme"
  fake_unzip "$unzipped"
  TEST_SHELL=/bin/zsh run_install "$unzipped/install.sh"
  printf '\n# updated upstream\n' >>"$unzipped/random-theme.zsh"
  TEST_SHELL=/bin/zsh run_install "$unzipped/install.sh"
  assert_count "$HOME_DIR/.ghostty-random-theme/random-theme.zsh" '# updated upstream' 1 "re-running refreshes the installed copy"
  cleanup
}

test_shell_override() {
  new_home
  TEST_SHELL=/bin/zsh run_install "$INSTALL" --shell bash
  assert_count "$HOME_DIR/.bashrc" "$SOURCE_LINE_BASH" 1 "--shell bash overrides \$SHELL detection"
  assert_no_file "$HOME_DIR/.zshrc" "--shell bash leaves .zshrc alone"
  cleanup
}

test_rc_override() {
  new_home
  local custom="$HOME_DIR/.config/custom_rc"
  mkdir -p "$HOME_DIR/.config"
  TEST_SHELL=/bin/zsh run_install "$INSTALL" --rc "$custom"
  assert_count "$custom" "$SOURCE_LINE_ZSH" 1 "--rc writes to the named file"
  assert_no_file "$HOME_DIR/.zshrc" "--rc suppresses the default rc target"
  cleanup
}

test_unsupported_shell() {
  new_home
  TEST_SHELL=/usr/bin/fish run_install "$INSTALL"
  assert_status $? 1 "exits non-zero for an unsupported shell"
  assert_no_file "$HOME_DIR/.zshrc" "writes nothing for an unsupported shell"
  if grep -qi 'fish' "$SANDBOX/out"; then
    ok "error message names the offending shell"
  else
    no "error message names the offending shell" "output was: $(cat "$SANDBOX/out")"
  fi
  cleanup
}

test_bad_flag() {
  new_home
  TEST_SHELL=/bin/zsh run_install "$INSTALL" --nonsense
  assert_status $? 1 "exits non-zero on an unknown flag"
  cleanup
}

test_help_flag() {
  new_home
  TEST_SHELL=/bin/zsh run_install "$INSTALL" --help
  assert_status $? 0 "--help exits 0"
  assert_no_file "$HOME_DIR/.zshrc" "--help changes nothing"
  cleanup
}

# --- run --------------------------------------------------------------------

if [ ! -f "$INSTALL" ]; then
  echo "install.sh not found at $INSTALL" >&2
  exit 1
fi

section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

section "zsh"
test_zsh_fresh
test_zsh_idempotent
test_zsh_no_trailing_newline
test_zsh_preserves_existing_content
test_zdotdir

section "bash"
test_bash_no_profile
test_bash_profile_needs_chain
test_bash_profile_already_chained_dot_home
test_bash_profile_already_chained_source_tilde
test_bash_chain_idempotent

section "script copying"
test_copies_from_elsewhere
test_rc_line_is_tilde_not_absolute
test_survives_source_deletion
test_run_from_canonical_dir
test_reinstall_updates_copy

section "flags and errors"
test_shell_override
test_rc_override
test_unsupported_shell
test_bad_flag
test_help_flag

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
echo
[ "$fail" -eq 0 ]
