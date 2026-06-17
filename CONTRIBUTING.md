# Commit Message Convention

## Format

```
<scope>(<target>): <subject>

<body>

<footer>
```

- All lines must not exceed 72 characters.
- All commit messages are written in English.

### Subject

- Must not exceed 50 characters.
- Use imperative mood (e.g. `add`, not `added` / `adding`).
- Do not end with a period.
- Start with a lowercase letter unless the first word is a proper noun.

### Scope and Target

The scope identifies the dimension of the package affected by the change.

| Scope | Meaning | Target example |
|-------|---------|----------------|
| `base` | Foundation package source | `events`, `types`, `errors`, `llm`, `tools`, `config` |
| `test` | Test suite | `events`, `runtests` |
| `docs` | Documentation | `readme`, `api`, `getting-started` |
| `meta` | Infrastructure and package metadata | `ci`, `contributing`, `project`, `compat` |
| `repo` | Repository management | `gitignore`, `license` |

- `target` is the slug of the affected entry, without path prefix or trailing `/`.
- For `base`, `target` is the source subdirectory or module touched.
- For `meta`, `target` describes the changed object rather than a module name.

### Body

- Separate from subject with one blank line.
- Use imperative mood.
- Explain **why** the change was made, not **what** was changed.
- Each line must not exceed 72 characters.
- Use unordered lists (`-`) to enumerate specific changes.

### Footer

- AI-assisted commits **must** include an `Assisted-by` trailer.
- Purely human commits require no footer trailer.
- The `Co-authored-by` trailer is **prohibited** for AI attribution.

## Development

Run the package test suite from this repository root:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

When this package is updated from the FytcAgents integration workspace, commit
and push the change here first. Then update the parent workspace's submodule
pointer in a separate parent commit.

## AI Attribution

Based on the [Linux Kernel AI Coding Assistants](https://docs.kernel.org/process/coding-assistants.html) guidelines.

### Format

```
Assisted-by: AGENT_NAME:MODEL_NAME
```

### Rules

- AI tools **must not** add `Signed-off-by` tags; only humans can legally certify the Developer Certificate of Origin.
- The human committer is responsible for reviewing all AI-generated content and taking full responsibility for the contribution.
- When multiple AI tools assisted, use one `Assisted-by` line per tool.
- The `Co-authored-by` trailer is **prohibited** for AI attribution.

### Canonical Agent Names

`AGENT_NAME` must exactly match one of the following entries:

| AGENT_NAME | Description |
|------------|-------------|
| `Codex` | OpenAI Codex |
| `ClaudeCode` | Anthropic Claude |
| `QwenCode` | Alibaba Qwen Code |
| `GitHub-Copilot` | GitHub Copilot |
| `OpenCode` | OpenCode CLI |

To add a new agent, append a row to this table in `CONTRIBUTING.md`.

### Canonical Model Names

`MODEL_NAME` should be lowercase and may include version numbers or descriptors
to specify the exact model used, e.g. `gpt-5.5`, `gemini-3.1-pro-preview`,
`glm-5.1`, `claude-opus-4.6`.

### Examples

```
base(events): add EventBus with emit! dispatch

- The foundation package needs a shared, dependency-light event
  channel before downstream packages can observe execution
- A built-in console listener gives users zero-config tracing

Assisted-by: Codex:gpt-5.5
```
