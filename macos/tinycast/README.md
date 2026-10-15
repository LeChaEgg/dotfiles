# Tinycast

This directory contains the portable Tinycast configuration managed by the
dotfiles installer:

- `Snippets/` is linked into Tinycast's Application Support directory.
- `quicklinks.sql` seeds the tracked quicklinks.
- `apply-settings.sh` restores shortcuts and non-secret preferences.

AI connections, API keys, clipboard history, screenshots, extension bundles,
and app caches are intentionally not tracked. Use Tinycast's own Backup export
for a full private backup outside this repository.
