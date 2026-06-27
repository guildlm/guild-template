# Contributing to guild-template

This repo is the boilerplate every GuildLM guild starts from, so changes here
ripple to all future guilds. Keep it minimal, correct, and faithful to the core
tools.

## Ground rules

- **Mirror the reference guild.** The skeleton must stay structurally identical
  to [guild-code](https://github.com/guildlm/guild-code). If guild-code changes
  its layout, update the skeleton to match.
- **Schema-faithful.** Generated recipes must validate against the real loaders:
  forge (`forge/configs/example.yaml`), anvil (`anvil/src/config.py`), crucible
  (`crucible/suites/*.yaml`). Never add fields those loaders don't define.
- **Offline-first.** Generated recipes/suites must run with no network and no GPU.
- **POSIX sh.** `new_guild.sh` is `/bin/sh`, not bash — no arrays, no `[[ ]]`.

## Validate before opening a PR

```bash
# Script is syntactically valid and (if available) shellcheck-clean
bash -n new_guild.sh
shellcheck new_guild.sh        # if installed

# Skeleton YAML parses as-is (tokens are quoted)
find skeleton -name '*.yaml' -print0 | xargs -0 -I{} \
  python3 -c "import sys,yaml; yaml.safe_load(open(sys.argv[1]))" {}

# A generated guild parses and loads with the real tools
OUT_DIR=/tmp/guild-sql ./new_guild.sh guild-sql sql sql_writer
find /tmp/guild-sql -name '*.yaml' -print0 | xargs -0 -I{} \
  python3 -c "import sys,yaml; yaml.safe_load(open(sys.argv[1]))" {}
rm -rf /tmp/guild-sql
```

## Editing the skeleton

- Quote placeholder tokens in YAML (`name: "{{SPECIALIST}}"`) so the skeleton
  itself stays parseable.
- Keep `{{GUILD_NAME}}`, `{{DOMAIN}}`, `{{SPECIALIST}}` as the only tokens. If
  you need another, add its substitution to `new_guild.sh` and document it in
  the README token table.

## License

By contributing, you agree your contributions are licensed under the Apache
License 2.0.
