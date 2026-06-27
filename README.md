# guild-template 📋

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](./LICENSE)
[![Template](https://img.shields.io/badge/use-this%20template-C5A55A.svg)](https://github.com/guildlm/guild-template/generate)

**The boilerplate for building a new [GuildLM](https://github.com/guildlm/guildlm.github.io) guild.**

A *guild* is a domain (code, sql, legal, …) served by a small team of specialist
SLMs. This repo gives you a ready-made skeleton plus a one-command generator so a
new guild is wired into the four core tools — [forge](https://github.com/guildlm/forge)
(data), [anvil](https://github.com/guildlm/anvil) (training),
[crucible](https://github.com/guildlm/crucible) (eval) and
[brain](https://github.com/guildlm/brain) (serve/route) — from minute one.

```
 forge ───▶ anvil ───▶ crucible ───▶ brain
 (data)     (train)    (evaluate)    (serve & route)
```

The reference implementation is [guild-code](https://github.com/guildlm/guild-code)
(the Go Code Guild). This template mirrors its structure exactly.

---

## What's in here

```
guild-template/
├── new_guild.sh            # generator: copy skeleton + substitute tokens
├── README.md               # this guide
├── GETTING_STARTED.md      # worked example: build "guild-sql" end to end
├── CONTRIBUTING.md
├── LICENSE                 # Apache-2.0
└── skeleton/               # the template tree (placeholder tokens inside)
    ├── README.md
    ├── .gitignore
    └── {{DOMAIN}}/
        ├── guild.yaml
        ├── forge/{{SPECIALIST}}.yaml
        ├── anvil/{{SPECIALIST}}.yaml
        ├── crucible/{{SPECIALIST}}.yaml
        ├── crucible/data/{{SPECIALIST}}.jsonl
        ├── prompts/{{SPECIALIST}}.txt
        └── tools/run_tests.sh
```

### Placeholder tokens

The skeleton uses three tokens that `new_guild.sh` substitutes:

| Token             | Meaning                                   | Example          |
| ----------------- | ----------------------------------------- | ---------------- |
| `{{GUILD_NAME}}`  | Repository / guild name                   | `guild-sql`      |
| `{{DOMAIN}}`      | Short domain id (directory + routing)     | `sql`            |
| `{{SPECIALIST}}`  | A specialist id (one recipe set each)     | `sql_writer`     |

---

## Quick start

### Option A — GitHub template

```bash
gh repo create guildlm/guild-sql --template guildlm/guild-template
cd guild-sql
./new_guild.sh guild-sql sql sql_writer sql_optimizer sql_explainer
```

### Option B — clone and scaffold locally

```bash
git clone https://github.com/guildlm/guild-template
cd guild-template
./new_guild.sh guild-sql sql sql_writer sql_optimizer sql_explainer
# -> ./guild-sql/ with one forge/anvil/crucible/prompt set per specialist
```

`new_guild.sh <guild-name> <domain> [specialist ...]` refuses to overwrite an
existing directory; set `OUT_DIR=...` to choose the destination. With no
specialists it creates a single `<domain>_specialist`. Run `./new_guild.sh -h`
for the full usage.

---

## Step-by-step: from skeleton to a live guild

> A complete, concrete version of these steps is in
> [GETTING_STARTED.md](./GETTING_STARTED.md).

### 1. Scaffold

```bash
./new_guild.sh guild-sql sql sql_writer sql_optimizer sql_explainer
cd guild-sql
```

### 2. Fill in `guild.yaml`

Edit `sql/guild.yaml`: set each specialist's `tasks`, `brief`, the guild
`description`, and `routing_keywords` the brain uses to reach this domain. Every
specialist's `brain_id` must match what you'll register in the brain (step 7).

### 3. Write the forge data recipe(s)

For each specialist, edit `sql/forge/<id>.yaml`:

- `query` — the source query (GitHub, arXiv, …) for your domain.
- `process.include_extensions` / lengths — what counts as a document.
- `generate.roles` — must be **registered teacher roles** in forge. If your
  domain needs a new role, add a `Role(...)` to
  `forge/src/core/instruction_gen.py` (see the note in the generated recipe).

### 4. Build the dataset with forge

```bash
# from a forge/ checkout, with guild-sql cloned alongside it
forge run --config ../guild-sql/sql/forge/sql_writer.yaml
# -> forge/data/datasets/sql_writer_v1.train.jsonl (+ .validation.jsonl, manifest)
```

Recipes default to `generate.offline: true`, so this runs with no GPU/teacher.

### 5. Train with anvil

```bash
# from an anvil/ checkout — copy the recipe so named refs resolve
cp ../guild-sql/sql/anvil/sql_writer.yaml configs/guilds/
anvil-train --config configs/guilds/sql_writer.yaml
# -> ./checkpoints/sql_writer_adapter/  (a LoRA adapter)
```

Use `lora: high_rank` for hard reasoning specialists; keep `default` otherwise.

### 6. Evaluate with crucible

```bash
# from the guild repo; runs every suite under sql/crucible/
sql/tools/run_tests.sh
```

Pick evaluators in each `sql/crucible/<id>.yaml` that fit the output:
`go_functional`-style executable evaluators for code, `llm_judge` + `safety`
for prose. Replace the sample rows in `sql/crucible/data/` with real predictions.

### 7. Register in the brain

Add each specialist to `brain/configs/guilds.yaml` under `specialists:`, using
the same `brain_id`, `model`, `lora` (your published adapter) and `system_prompt`
as your `guild.yaml`. Add a `pipelines:` entry if the guild has a multi-step flow.

```bash
brain ask "Write a SQL query that ..."   # the brain routes it to your guild
```

---

## Conventions to keep

- **Schema-faithful.** Every recipe must validate against the real loaders
  (forge `configs/example.yaml`, anvil `src/config.py`, crucible `suites/*.yaml`).
- **Offline-first.** Recipes/suites must run with no network and no GPU.
- **Brain-aligned.** `guild.yaml` ids and prompts mirror `brain/configs/guilds.yaml`.

## License

Apache-2.0 — see [LICENSE](./LICENSE). Generated guilds inherit this license.
