# Zsh dotfiles migration

Layout:

- `.zshrc` — bootstrap, PATH, conda initialization, module sourcing, and `zhelp`
- `zsh/files.zsh` — file/directory utilities
- `zsh/data.zsh` — CSV/text-data utilities
- `zsh/media.zsh` — image/audio/video/OCR utilities
- `zsh/dev.zsh` — developer/server/Homebrew utilities
- `zsh/text.zsh` — text utilities
- `zsh/macos.zsh` — macOS/network utility

Migration notes:

- Current Zsh behavior was treated as authoritative where versions differed.
- The later duplicate `bud` definition wins, so `bud` remains `brew update && brew upgrade` (no cleanup).
- Help-enabled wrappers from the older Zsh version were restored where the current file had reverted to aliases/one-liners.
- `tiffconvert` and `colcp` from the current Zsh file were retained; `tiffconvert` gained `--help`.
- Bash-only source commands `ocr`, `append-txt-extension`, `copy-matching-photos`, and `fake-scan` were carried into Zsh.
- Bash `combinetext` was not used because its `uniq -u` semantics differ from the current Zsh `sort -u`; the current Zsh behavior was preserved.
- Every discoverable command has a `# @cmd name - description` record for `zhelp`.

Install by placing this directory at `~/dotfiles`, backing up the existing `~/.zshrc`, and symlinking `~/dotfiles/.zshrc` to `~/.zshrc`.

## Command naming

See [`../CONSTITUTION.md`](../CONSTITUTION.md). User-facing shell commands use
lowercase **kebab-case** (`-` between words), not underscores. For example,
`filter-http`, `split-buckets`, `copy-matching-photos`, `reset-mac`, and
`append-txt-extension`. The `# @cmd` index and `--help` examples must match
the function name. Older underscore names are no longer defined.
