# {{GUILD_NAME}} ⚔️

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](./LICENSE)
[![Guild](https://img.shields.io/badge/guild-{{DOMAIN}}-C5A55A.svg)](./{{DOMAIN}}/guild.yaml)
[![Status](https://img.shields.io/badge/status-draft-lightgrey.svg)](#specialists)

**A [GuildLM](https://github.com/guildlm/guildlm.github.io) guild — specialist
SLMs for the {{DOMAIN}} domain.**

This repository holds the **specs and recipes** for {{GUILD_NAME}}: per
specialist, a [forge](https://github.com/guildlm/forge) data recipe, an
[anvil](https://github.com/guildlm/anvil) training recipe, a
[crucible](https://github.com/guildlm/crucible) eval suite, and a system prompt,
plus a single `{{DOMAIN}}/guild.yaml` manifest the [brain](https://github.com/guildlm/brain)
registers. It contains no model weights and no training code.

```
 forge ───▶ anvil ───▶ crucible ───▶ brain
 (data)     (train)    (evaluate)    (serve & route)
```

## Specialists

| Specialist          | Tasks | Base model | LoRA      | Status |
| ------------------- | ----- | ---------- | --------- | ------ |
| `{{SPECIALIST}}`    | TODO  | Qwen2.5-7B | `default` | 🟡 draft |

> Fill this table in as you add specialists. Each must also be registered in
> `brain/configs/guilds.yaml` with the matching `brain_id`.

## Layout

```
{{DOMAIN}}/
├── guild.yaml       # guild + specialist manifest (brain-aligned)
├── forge/           # data recipes      (forge schema)
├── anvil/           # training recipes  (anvil schema)
├── crucible/        # eval suites + sample data (crucible schema)
├── prompts/         # system prompts
└── tools/
    └── run_tests.sh # run all crucible suites for this guild
```

## Lifecycle

```bash
forge run --config {{DOMAIN}}/forge/{{SPECIALIST}}.yaml      # 1. build dataset
cp {{DOMAIN}}/anvil/{{SPECIALIST}}.yaml ../anvil/configs/guilds/
anvil-train --config configs/guilds/{{SPECIALIST}}.yaml      # 2. train adapter
{{DOMAIN}}/tools/run_tests.sh                                # 3. evaluate
# 4. register the adapter in brain/configs/guilds.yaml and serve
```

See the [guild-template guide](https://github.com/guildlm/guild-template) for
the full walkthrough.

## License

Apache-2.0 — see [LICENSE](./LICENSE).
