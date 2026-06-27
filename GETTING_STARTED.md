# Getting started — building `guild-sql`

A concrete, end-to-end walkthrough that turns this template into a working SQL
guild with three specialists: `sql_writer`, `sql_optimizer`, and
`sql_explainer`. It assumes the core tool repos are checked out as siblings:

```
workspace/
├── forge/        anvil/        crucible/        brain/
├── guild-template/   (you are here)
└── guild-sql/        (created below)
```

---

## 0. Prerequisites

- Python 3.11+ and the core tools installed (`pip install -e .` in each of
  forge/anvil/crucible/brain, or at least forge + crucible for an offline run).
- Docker only if a specialist uses an executable evaluator (SQL doesn't here).

---

## 1. Scaffold the guild

```bash
cd workspace/guild-template
./new_guild.sh guild-sql sql sql_writer sql_optimizer sql_explainer
```

This creates `guild-sql/` with one forge/anvil/crucible/prompt set per
specialist and all tokens substituted:

```
guild-sql/
├── README.md  .gitignore  LICENSE
└── sql/
    ├── guild.yaml
    ├── forge/{sql_writer,sql_optimizer,sql_explainer}.yaml
    ├── anvil/{sql_writer,sql_optimizer,sql_explainer}.yaml
    ├── crucible/{sql_writer,sql_optimizer,sql_explainer}.yaml
    ├── crucible/data/{sql_writer,sql_optimizer,sql_explainer}.jsonl
    ├── prompts/{sql_writer,sql_optimizer,sql_explainer}.txt
    └── tools/run_tests.sh
```

```bash
cd workspace/guild-sql
```

---

## 2. Describe the guild — `sql/guild.yaml`

Fill in the `TODO`s. For example:

```yaml
guild:
  id: "sql"
  name: "guild-sql"
  domain: "sql"
  status: draft
  description: >-
    SQL specialists — query authoring, optimization and explanation — for
    Postgres-flavoured SQL.
  routing_keywords: ["sql", "query", "postgres", "join", "index", "explain"]

specialists:
  - id: "sql_writer"
    brain_id: "guild-sql/sql_writer"
    tasks: [generation]
    lora_recipe: default
    lora_adapter: "guildlm/sql_writer-lora"
    prompt: "sql/prompts/sql_writer.txt"
    forge: "sql/forge/sql_writer.yaml"
    anvil: "sql/anvil/sql_writer.yaml"
    crucible: "sql/crucible/sql_writer.yaml"
    brief: Writes correct, readable SQL from a natural-language request.
  # ... sql_optimizer (tasks: [optimization]), sql_explainer (tasks: [explanation])
```

Write each system prompt in `sql/prompts/<id>.txt` (the skeleton leaves a scaffold).

---

## 3. Write the forge recipes — `sql/forge/*.yaml`

SQL lives in many GitHub repos. For `sql_writer`:

```yaml
source: github
query: "language:sql stars:>500 NOT awesome NOT tutorial"
process:
  include_extensions: [".sql"]
  min_length: 120
generate:
  offline: true
  roles:
    - "sql_writer"     # must be registered in forge (next step)
```

### Register the teacher role in forge

Forge only ships Go roles. Add SQL roles to
`workspace/forge/src/core/instruction_gen.py` in the `for _role in (...)` loop:

```python
Role(
    "sql_writer",
    "You are an expert SQL engineer. Write correct, readable, portable SQL.",
    "write a SQL query that satisfies a requirement derived from the schema",
),
```

(Repeat for `sql_optimizer` and `sql_explainer`.)

---

## 4. Build the datasets — forge

```bash
cd workspace/forge
forge run --config ../guild-sql/sql/forge/sql_writer.yaml
forge run --config ../guild-sql/sql/forge/sql_optimizer.yaml
forge run --config ../guild-sql/sql/forge/sql_explainer.yaml
# -> data/datasets/sql_*_v1.train.jsonl (+ .validation.jsonl, manifests)
```

Offline mode emits deterministic synthetic pairs so this works with no GPU. For
real data: set `generate.offline: false` and export `FORGE_TEACHER_BASE_URL`,
`FORGE_TEACHER_API_KEY`, `FORGE_TEACHER_MODEL`.

---

## 5. Train the adapters — anvil

```bash
cd workspace/anvil
cp ../guild-sql/sql/anvil/sql_writer.yaml configs/guilds/
anvil-train --config configs/guilds/sql_writer.yaml
# -> ./checkpoints/sql_writer_adapter/
```

The recipe references `base_model: qwen2.5_7b` and `lora: default`, which resolve
against `anvil/configs/`. Bump to `lora: high_rank` for `sql_optimizer` if query
rewriting needs more capacity.

---

## 6. Evaluate — crucible

The generated suites use `llm_judge` + `safety` (SQL output is graded as text).
Drop your model's predictions into `sql/crucible/data/*.jsonl`, then:

```bash
cd workspace/guild-sql
sql/tools/run_tests.sh            # all specialists
sql/tools/run_tests.sh sql_writer # just one
```

Judge suites run offline by default; set `CRUCIBLE_JUDGE_BASE_URL` / `_API_KEY` /
`_MODEL` to grade with a real judge model.

---

## 7. Register with the brain

Add the specialists to `workspace/brain/configs/guilds.yaml`:

```yaml
specialists:
  - id: guild-sql/sql_writer
    guild: sql
    domain: sql
    languages: [sql]
    tasks: [generation]
    model: qwen2.5:7b-instruct
    lora: guildlm/sql_writer-lora
    system_prompt: >-
      You are an expert SQL engineer in the GuildLM SQL Guild. Write correct,
      readable, portable SQL; explain assumptions about the schema.
```

Then:

```bash
cd workspace/brain
brain ask "Write a query to find the top 5 customers by revenue this quarter"
# Brain classifies -> domain sql -> routes to guild-sql/sql_writer
```

That's a complete guild: **scaffold → describe → data → train → eval → serve.**
Copy the same loop to add specialists or stand up another domain.
