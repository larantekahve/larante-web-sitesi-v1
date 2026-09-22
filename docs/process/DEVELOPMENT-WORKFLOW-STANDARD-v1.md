# Development Workflow Standard v1 (DWS-1)

| Field | Value |
|---|---|
| Version | 1.0 — draft r2, 2026-09-22 (r1 + owner decisions of 2026-09-22: Agent Skills integration, Jev routing policy, quota-aware fallback, checkpoint/resume contract; reviewed by a bounded 2-agent workflow, findings G01–G18 applied; see §11) |
| Status | DRAFT — takes effect when the owner merges this document (or states in a task command that the draft applies) |
| Owner | project owner (GitHub `larantekahve`); only the owner amends this standard |
| Applies to | every AI-assisted development task that the owner starts with the one-command protocol (§2); project-agnostic core §1–§12, project binding in Annex L |
| Origin | lessons from P1-T01 (`larante-platform`, 2026-09-18 … 2026-09-22): 5 plan-review rounds, 11 fresh code inspections, 24 reviewer findings, one 178-candidate red-team workflow, one usage-limit failure — see §0 |
| Canonical copy | this file; a byte-identical copy ships inside the Claude Code user skill `dev-workflow-standard` so the protocol works in any repository (Annex L §L1) |

Normative words: **MUST / MUST NOT** are hard rules; **SHOULD** is the default that a task record may override with a written reason; **MAY** is optional.

---

## 0. Why this standard exists (what P1-T01 taught)

| Observation from P1-T01 | Rule that answers it |
|---|---|
| Ten consecutive REVISE inspections on one lint rule, each fixing one more syntax variant of the same root class (R09–R16 ended only when the evaluator was removed and the contract narrowed) | Every finding carries a *root class*; the third fix of the same root class is prohibited and triggers a design stop (§4.4, §5.4) |
| A 178-candidate red-team workflow (4 lenses, 68 verifier agents) was launched without a written scope; useful, but unbounded and expensive | Attack matrices need a written target surface and a hard cap that lives inside the task's agent budget (§4.3) |
| Reviewer findings were sometimes outside the agreed contract (loader machinery, cache integrity owned by another task) and were still treated as fix candidates until the owner intervened | Every finding is classified A/B/C/D before anything is patched; only A is auto-fixable (§5.2) |
| One inspection "failed" on a Codex usage limit and could have been misread as a verdict, and a builder or reviewer quota could have stopped the whole task | A reviewer result counts only when `status == completed` and the verdict is present; quota events trigger the checkpoint-and-fallback policy (§8.5) without lowering the security bar |
| The plan was SHA-bound, every inspection was fresh, every fix was a separate authorised commit, evidence was reproducible — this worked | Keep: plan SHA binding, fresh inspections, per-finding commits, evidence-grade validation, and a checkpoint record that lets another model resume (§2, §7, §10, §12) |
| Owner rules were repeated in every prompt (no merge, no deploy, no global config change, no weakening tests) | Standing rules live here once (§6, §7, Annex L §L5) so the one-command protocol can rely on them |

---

## 1. Roles and capabilities (reuse what is installed; do not duplicate)

The capability inventory of 2026-09-22 (Annex L §L2 records the exact installation) maps to fixed roles. A task MUST use the capability in the "How" column; it MUST NOT re-implement a capability that exists.

| Role | Capability | How it is used | Notes |
|---|---|---|---|
| Orchestrator, planner, default builder | Claude Code host session (Claude Fable 5.1, effort high); builder fallback Claude Opus 5 HIGH under §8.5 | runs stages S0–S10 (§2) in the current conversation | The host is accountable for every artefact; delegation never removes that accountability; a builder change never restarts the task (§12) |
| Independent plan reviewer | Codex CLI through the `claudex-loop` runner, `review` mode (`--resume` for further rounds, host-authored `--feedback`), launched with the **dedicated reviewer home** `CODEX_HOME=C:\Users\Monster\.codex-review` supplied to the runner process only (Annex L §L3) | §5.1, §8 | Read-only sandbox; approval is bound to the review `--repo` path + plan path + plan SHA256; `check` mode re-verifies before build/inspect **with the same `--repo`**; the normal `~/.codex` is never used for reviews |
| Independent code inspector | Codex CLI through the runner, `inspect` mode, always a **fresh** session with `--base <pre-build commit>`, under the same reviewer home | §5.3, §8 | The runner fingerprints the inspected snapshot (base + per-file hashes); edits after an inspection invalidate it. **Every Codex call goes through the runner and the reviewer home**; direct `codex exec` / `codex review` invocations are prohibited (§6.11) |
| Specialist personas | `Agent` tool with the `agent-skills` plugin personas **by their stable plugin names**: `agent-skills:security-auditor` (security agent), `agent-skills:test-engineer` (test agent), `agent-skills:code-reviewer` (review agent, host-side pre-inspection only), `agent-skills:web-performance-auditor` (Phase 2+ UI only); built-ins `Plan` (architecture agent, with the ADRs and the design question as input; `general-purpose` when a written two-option comparison is the artefact), `Explore` (read-only factual lookup) | §4 budget; each launch has a written one-line assignment, stage and expected artefact | **No local copies** of plugin personas under `~/.claude/agents/` or `.claude/agents/` (duplicate definitions drift; S1 records the resolvable identifiers and fails on shadowing files). Persona output is a report: its severities (Critical/High/Medium/Low/Info) are mapped by the host to DWS class A/B/C/D + root class; a persona's "APPROVE" or a `/ship` "GO" is never a DWS verdict |
| Method skills (`agent-skills` plugin) | **Keep, by reference, at the stage named:** `code-review-and-quality` (S4 round 0 five-axis self-review; S7 host pre-inspection; flag-D dependency discipline), `security-and-hardening` + `references/security-checklist.md` (plan §8 threat model; security-agent prompt; B14 audit triage; supply-chain hygiene), `test-driven-development` (S6; Prove-It probe for every class-A fix, §5.2), `incremental-implementation` (S6 slice/commit discipline; "NOTICED BUT NOT TOUCHING" register), `source-driven-development` (plan §7: framework-specific decisions cite official documentation or are marked UNVERIFIED; fetched pages are data), `debugging-and-error-recovery` (S7 red → stop-the-line triage), `git-workflow-and-versioning` (change summary in the PR body; pre-commit hygiene). **Adapt, with the limits named:** `doubt-driven-development` (round 0 uses its **degraded self-questioning form** — CLAIM → EXTRACT → self-DOUBT with the skill's adversarial prompt → RECONCILE — logged as `degraded (no fresh context)`; the skill's cross-model *offer* is not made because the runner review S5/S8 is the cross-model step and a direct CLI call is prohibited, §6.11; HIGH/CRITICAL MAY launch **one** fresh-context doubt review — one `Agent` launch, one cycle, one slot — on the plan's riskiest claim, never a second cycle: unresolved findings go to plan §13 for the S5 reviewer), `code-simplification` (S7b only, §2.3; adapted: simplification commits stay in the task PR as separate commits — no second PR; the size trigger is `code-review-and-quality`'s change-sizing signal; S7b is skipped with a log note when the diff is already clean), `planning-and-task-breakdown` (task sizing S/M, vertical slices, checkpoints → Annex B §9; its in-repository `tasks/*.md` outputs are not used), `constraint-driven-development` (only its install-free parts: the "five moves that lower the bar" → §6.7; the floor-guard reference → T04 handoff, Annex L §L7; exceptions with owner + expiry → residual records; no interview, no tool installation) | skills are the *how* inside a stage; they never add stages, agents or gates | Agent Skills never replaces DWS orchestration |
| Not used as DWS orchestrators | `spec-driven-development`, `/spec` (writes `SPEC.md` into the repository; the task contract + ADRs are the spec), `/plan` (writes `tasks/plan.md` / `tasks/todo.md` into the repository; the plan lives outside, §2.4), `/build auto` (single-approval autonomous run that skips S5/S8/§9), `/constraints` (installs tools; §1 no-new-software), `using-agent-skills` (a second router; DWS is the router), `/ship` as a decision (its 3-persona fan-out MAY be used as the HIGH/CRITICAL host pre-inspection package inside the budget; its GO/NO-GO is not a verdict) | — | Plugin hooks that write into repositories or mutate files during reads (`simplify-ignore`, `sdd-cache`) are **never wired** for these repositories (§6.12); `session-start` is not wired (Claude Code routes skills natively) |
| Bounded multi-agent workflow ("Ultracode") | Claude Code `Workflow` tool (`workflow-authoring` reference) | only under §4.3 (written target surface, cap inside the budget, one run) | Never as a substitute for a plan; never for open-ended syntax hunts |
| Routing advice | `claudex-route` skill and, once integrated, **Jev** (§8.6) — both recommendation-only | `claudex-route` MAY be consulted when the reviewer/model choice is unclear; Jev is requested **exactly once per task, at S3**, and recorded (shadow mode) | Advice never overrides the deterministic tables (§3, §4, §8); in shadow mode it changes no decision, not even upward |
| Explicit alternative builder | `codex-build` / `codex-review` compatibility skills (`builder=codex`) | permitted **only** for LOW/MEDIUM tasks without flag G **whose task contract does not require a Codex inspection** (under the Larante Phase 1 contract minimum, Annex L §L5, it is therefore not available) and only when the owner names it; the runner then forces a fresh **Claude** inspector, which becomes that task's §8.3 final reviewer (recorded as an owner decision) | HIGH/CRITICAL, flag G and every contract that mandates Codex inspection MUST be built by Claude, because the final verdict must come from Codex |
| User-triggered cloud review | `/code-review ultra` (ultrareview) | owner only; billed | Claude MUST NOT launch it; it is a supplementary owner tool, not a stage of this standard |

**No new software.** A task MUST NOT install, enable or configure new third-party software (Claude/Codex plugins, MCP servers, CLIs, GitHub Apps, global packages, editor extensions, hooks) or add project dependencies beyond the task's "Files allowed" without an owner statement. A needed capability that Annex L §L2 does not list is an owner question (§9.1) and the task stops there. Jev is not installed or connected until its integration method, permissions, data exposure and required software are reviewed and owner-approved (§8.6).

---

## 2. Task lifecycle — the one-command protocol

### 2.1 The command

The owner starts a task with one sentence of the form:

```
Execute <TASK-ID> using Development Workflow Standard v1.
```

Optional qualifiers, all written by the owner in the same message:

| Qualifier | Meaning |
|---|---|
| `level=LOW|MEDIUM|HIGH|CRITICAL` | overrides the classifier. **Upward:** apply and record. **Downward:** apply and record as an owner decision, **except** when the classifier matched a CRITICAL trigger or a HIGH trigger of the authentication / authorization / inventory-concurrency / secrets kind — then S3 stops with the single question "classifier says `<level>` because `<trigger>`; confirm `<owner level>`?" (§9.7) |
| `reviewer=<model id>` | overrides §8.3 upward at any time; downward only as a recorded owner decision |
| `builder=<model id>` | names the builder explicitly (default Fable 5.1 HIGH; fallback Opus 5 HIGH per §8.5); `builder=codex` only where §1 permits it (LOW/MEDIUM, no flag G, a contract without a Codex-inspection requirement) |
| `plan-only` | stop after S5 |
| `dry-run` | stop after S3 and return the Intake Record (Annex A); a dry run writes only the Intake Record to the scratchpad — no task directory, checkpoint or Jev record is created and Jev is not requested (the once-per-task request of §8.6 belongs to the real run; the dry-run Intake Record says `Jev shadow: not requested (dry-run)`) |
| `budget=<n>` | agent budget override, recorded; never above the §4.1 ceiling of 8 without an owner sentence naming the number |
| `resume=<checkpoint path>` | continue a task from its checkpoint record (§12) instead of starting at S0 |

### 2.2 What the command authorises

| Authorised by the command itself | Requires a separate owner statement |
|---|---|
| read the task contract and references; preflight checks (read-only; `git fetch --prune` is permitted) | anything the task contract marks as an owner decision |
| create the task directory and files outside the product repository, including the checkpoint record | **CRITICAL tasks: starting S6** — the S5→S6 checkpoint is mandatory (§3.1, §9.2) |
| independent plan review rounds within §5.1 caps | more review rounds than the caps |
| create the task branch, implement, validate; switch to the fallback builder after a checkpoint when §8.5 triggers | any change outside the task's "Files allowed" (read with the repository's established mechanisms — Annex L §L6) |
| commit, push, open a **draft** PR, update its body | making the PR ready for review before an APPROVED final inspection by the reviewer §8.3 requires (a provisional review never suffices, §8.5) |
| fix class-A findings within §5.1 caps and re-inspect; obtain at most one provisional Sol plan review and one provisional inspection when Astra is evidenced unavailable (§8.5) | fixing class B/C/D findings |
| mark the PR Ready for Review after the required final inspection is APPROVED (or, for an inspection-exempt LOW task, after the logged "no inspection required" entry) and the S9 head check passes | **merge, deploy, delete branches, force-push, rewrite published history** (never authorised by this standard) |

### 2.3 Stages

Every stage has an entry condition, an exit artefact and a stop rule. Stages S0–S3 are read-only with respect to both repositories (fetching remotes is allowed; checkouts, branches and file writes are not). **At the end of every stage the host updates the checkpoint record (§12).**

| Stage | Name | Entry | Work | Exit artefact | Stop rule |
|---|---|---|---|---|---|
| S0 | Intake | owner command (or `resume=`) | read the task contract and every document it references; extract Goal, Scope, Out of scope, Files allowed, Security impact, Acceptance, Tests, Rollback, dependencies | Intake Record §A (draft); checkpoint created | contract missing a field that changes the deliverable → BLOCKED |
| S1 | Preflight | S0 | `git fetch --prune` in every repository; record the `origin/<default>` tip SHA as the task base and confirm that each dependency task's merge commit is an ancestor of it (`git merge-base --is-ancestor <merge> origin/<default>`), recording the dependency commit IDs (a stale local default branch is **reported, not silently advanced**); both repositories clean per Annex L §L4 B9; toolchain (runtime, package manager, CLIs); reviewer models listed in the Codex catalogue (`codex debug models`) with their availability state recorded (§8.5); the current Claude session model recorded as the builder (Claude availability is established only by a successful turn — the Opus 5 fallback stays `unverified` until used); **persona check**: the `Agent` tool's resolvable subagent types are listed and the exact identifier of each plugin persona recorded (`agent-skills:<name>` expected), and `~/.claude/agents/` and `<repo>/.claude/agents/` contain no file whose `name` is `code-reviewer`, `security-auditor`, `test-engineer` or `web-performance-auditor` (a match shadows the plugin persona → preflight FAIL, owner decision); **hook check**: `~/.claude/settings.json`, `~/.claude/settings.local.json` and `<repo>/.claude/settings*.json` contain no `hooks` entry referencing `simplify-ignore`, `sdd-cache` or `session-start` from the `agent-skills` plugin (a match → preflight FAIL, owner decision under §6.12); runner `roles`/`--help` reachable; **reviewer-isolation preflight** (§6.11; script Annex L §L3a): under the dedicated reviewer home, `mcp list --json` = `[]`, no locally installed plugin, every account-level remote connector row (`installed, enabled` in `plugin list`, a state local config cannot change) matched by a `[plugins."…"] enabled = false` block and neutralised by `features.apps = false`, feature families apps / computer_use / browser_use (+external, +full_cdp) / image_generation / hooks / js_repl / multi_agent / skill_mcp_dependency_install / skill_search = false, the config without `notify`, `[projects]`, `[mcp_servers]` or marketplaces, `sandbox_mode = "read-only"`, `approval_policy = "never"`, the reviewer home authenticated, and `CODEX_HOME` not exported in the shell — any failure is a **blocking reviewer-preflight failure** (§9.5) and reviews never fall back to `~/.codex`; task directory location | Preflight table in the Intake Record | any prerequisite unmet → report; do not "fix around" it |
| S2 | Risk classification | S1 | apply the trigger table §3.2 to the contract's Scope / Files allowed / Security impact; add flags (§3.3); record the deciding triggers (**deterministic hard rules — the floor**) | Level + flags with justification | owner `level=` handled per §2.1 |
| S3 | Routing | S2 | request Jev advice if integrated (shadow mode, §8.6) and record it; choose agents (§4) and reviewer/builder models (§8) from the deterministic tables; write the one-line assignment and stage of each agent and the reason each *plausible* agent is not used; mark first-use models; record availability-driven fallbacks | Agent roster + reviewer roster + Jev shadow record | `dry-run` stops here |
| S4 | Plan | S3 | write the plan (Annex B) outside the product repository; record the plan SHA256; **round 0 = host self-review**: the `doubt-driven-development` degraded self-questioning form (CLAIM → EXTRACT → self-DOUBT with the adversarial prompt → RECONCILE, logged `degraded (no fresh context)`; HIGH/CRITICAL MAY instead spend one budget slot on **one** fresh-context doubt review — one launch, one cycle — of the riskiest claim) plus the `code-review-and-quality` five axes on the plan's key file contents; findings folded into the plan before any external review | `PLAN.md` + `REVIEW-LOG.md` round 0 | a genuine owner decision surfaces → ask only that question |
| S5 | Plan review | plan review required (§8.2) | runner `review`; host classifies each finding (§5.2), revises, re-submits with `--feedback`; counters `plan round n/3` in the log; stop at cap | APPROVED result bound to the final plan SHA, or documented stop | `plan-only` stops here; cap reached without approval → owner; CRITICAL → mandatory checkpoint before S6 |
| S6 | Implement | approved plan — final, or provisional per §8.5 (CRITICAL: only after the owner statement that names the provisional status) — or LOW without external review | runner `check` with the review `--repo` when an external plan approval exists (§8.2); when no plan review was required, the round-0 self-review entry with the plan SHA is the approval record and `check` is skipped; create the task branch from the recorded `origin/<default>` tip (`git switch -c <branch> <sha>`); implement **only** the plan in thin slices (`incremental-implementation`: simplest thing that works, scope discipline, one logical change per commit, keep the tree buildable); tests first where behaviour changes (`test-driven-development`); per-plan-step commits; specialist agents per S3; anything noticed outside scope goes to the "NOTICED BUT NOT TOUCHING" register, never fixed | commits on the task branch | scope drift discovered → stop, record, ask |
| S7 | Validate | S6 | run the baseline validation set (Annex L §L4, including B17 secret scan) + the task-specific checks from the plan + one negative probe per S-flag sub-surface; capture evidence (command, exit code, relevant lines). **Red → stop the line** (`debugging-and-error-recovery`: preserve evidence, reproduce, localise, reduce, fix the root cause, guard with a test, re-verify); never weaken a check (§6.7) | validation table | fix within scope or report |
| S7b | Simplify (conditional) | S7 green **and** the task's diff exceeds ~300 changed lines or grows a file past ~1000 lines | `code-simplification` on the files the task touched only, behaviour-preserving, tests unchanged and green after every step; recorded as its own commit(s) | commit(s) + re-run of B3–B7 | never after S8's final inspection (it would invalidate the snapshot) |
| S7c | Host pre-inspection | S7/S7b green | an `Agent` launch of `agent-skills:code-reviewer` as one budget slot (the `/review` command is a host self-review in the main context and does not satisfy S7c), or for HIGH/CRITICAL the `/ship`-style fan-out of `code-reviewer` + `security-auditor` + `test-engineer` (three slots, launched **once**, with the §4.3 fan-out pre-check answered in writing) — that fan-out **is** the roster's security and test agents, not additional launches; the host maps findings to A/B/C/D + root class and fixes class A before the Codex inspection. For MEDIUM, S7c is the default use of a free second slot; the flag-S security agent runs after S7c and before S8 | pre-inspection entry in the log | skipped for LOW/MEDIUM when the roster has no slot left |
| S8 | Code inspection | S7 green (S7b/S7c done if used); **skipped** for a LOW task exempt from independent inspection by §3.1, §8.2 and its contract — the log then records "no inspection required" with the reason and S9 binds to the S7 validation evidence | runner `check` again when an external plan approval exists (same `--repo` as S5); runner `inspect` (fresh session, `--base`, host `--feedback` notes naming the S sub-surfaces and the root classes already fixed); classify findings; fix class A with a Prove-It probe (§5.2); re-validate affected checks; re-inspect **fresh**; counters `inspection n/3`; stop at cap; when the required reviewer is unavailable apply §8.5 (provisional review, gate pending) | final inspection result (or provisional result + pending gate) | same root class survives two rounds → §5.4 root-cause stop |
| S9 | Publish | S8 | push; create/update the PR (draft first); PR body = validation + review summary + `git-workflow-and-versioning` change summary (CHANGES MADE / DIDN'T TOUCH / POTENTIAL CONCERNS). **Before `Ready for Review`:** the final inspection required by §8.3 is APPROVED (not provisional) — or, for a LOW task for which §3.1, §8.2 and the task contract require no independent inspection, S7 is green and the log records "no inspection required" with the reason; `git status --porcelain` empty; `git rev-parse HEAD` equals the HEAD recorded in the log entry of that inspection (exempt path: the HEAD at which the S7 validation evidence was produced); the inspection's snapshot file hashes equal the disk state (exempt path: the file hashes recorded with the S7 evidence); any mismatch returns to S8 (new fresh inspection; exempt path: re-run S7) and the PR stays draft; both SHAs go into the PR body | PR link, state | never merge |
| S10 | Report + STOP | S9 or any stop | completion report (§10) with one of the three final states; update the append-only log; final checkpoint record; clean scratch artefacts out of the repositories | report | end of authority |

### 2.4 Artefact locations

| Artefact | Location | Rule |
|---|---|---|
| Plan, review log, reviewer feedback notes, runner artefacts, **checkpoint record** (§12), Jev shadow record | a task directory **outside both repositories** (Annex L §L3: `~/.claude/plans/<project>-<task-id>/`) | plan is never edited after approval; log is append-only; checkpoint is rewritten at every stage boundary |
| Validation evidence, probe scripts, red-team output | the session scratchpad (Annex L §L3) | never committed to a product repository unless the plan says a specific file is a deliverable |
| PR body | scratchpad draft → GitHub | contains SHA of the approved plan, validation table, inspection rounds, the inspected HEAD, the change summary; contains no secrets, no local user paths |

---

## 3. Risk levels

### 3.1 Levels and defaults

| Level | Typical tasks | Default workflow | Specialist agents | Independent review |
|---|---|---|---|---|
| **LEVEL 1 — LOW** | copy/text changes; simple isolated UI adjustment; low-risk non-security refactor; documentation | host implements; focused tests; host self-review | 0 (1 when flag S applies, §3.3) | none by default; when the task contract requires review (all Larante Phase 1 tasks, Annex L §L5): GPT-5.6 Sol HIGH plan review and code inspection under the §5.1 caps |
| **LEVEL 2 — MEDIUM** | ordinary feature; API addition without sensitive data; normal database/application behaviour; configuration, startup validation and tooling | host plans and builds; tests/build/typecheck/lint; independent Codex code inspection; plan review when §8.2 says so | max 2, relevant only | Codex **GPT-5.6 Sol HIGH** for plan review and code inspection (final inspection Astra only with flag G) |
| **LEVEL 3 — HIGH** | authentication; authorization; inventory/concurrency; sensitive API boundaries; webhooks; uploads; external integrations; security controls; static enforcement of an architecture or security boundary | host plans and builds; architecture agent when a design choice exists; security agent; test agent; targeted adversarial agent/workflow only under §4.3; complete validation | normally max 4 = **one** of {`Plan` architecture agent when a design choice exists \| fresh-context doubt review at S4} + the S7c fan-out {`code-reviewer`, `security-auditor`, `test-engineer`} launched once (the security and test agents of this row **are** those launches); up to 8 in total only when a §4.3 run is written | Codex **GPT-6 Astra HIGH** plan review **and** final code inspection |
| **LEVEL 4 — CRITICAL** | payments; destructive migrations; production data access; secrets/identity infrastructure; irreversible operations; major security-architecture change | HIGH workflow **plus a mandatory owner checkpoint after S5 and before S6**: the approved plan and its irreversible / business-sensitive decisions are presented and S6 starts only on an owner statement; explicit owner merge/deploy authorisation | normally max 4; up to 4 more, one per concrete written unresolved question that no existing artefact answers (ceiling 8 per task) | Astra HIGH throughout; checkpoint recorded in the log |

### 3.2 Trigger table (deterministic classification — the floor no advice can lower)

The level is the **highest** row whose trigger matches any item in the task's Scope, Files allowed or Security impact. The task file's own "Security impact" sentence is an input, not the verdict. The HIGH and CRITICAL lists are **closed**: a property not listed does not raise the level; it may set a flag (§3.3). The result of this table is the deterministic minimum: agents and the host MAY raise it, never lower it; Jev advice (§8.6) may raise it only after shadow mode ends and in shadow mode changes nothing.

| Trigger (any match) | Level |
|---|---|
| handles payment authorisation/capture/refund; **reads or writes production data or connects to a production system** (database, service, dashboard, real provider credentials); runs a migration that drops, rewrites or truncates data; creates, rotates, stores or transmits secrets or signing keys (reading configured values by variable name in application config is **not** storing or transmitting secrets — that is flag S on the level the other triggers give); changes identity infrastructure (password hashing, session/token issuance, 2FA); performs an operation that cannot be rolled back by reverting the change | CRITICAL |
| authenticates or authorises principals; enforces tenant or role isolation; reads or writes inventory quantities, reservations or anything under a concurrency invariant; exposes or consumes an API boundary carrying personal, financial or tenant data; receives webhooks; accepts uploads; integrates an external provider; implements a runtime security control for production traffic (CSRF, rate limit, sanitisation, security headers, encryption); **static enforcement of an architecture or security boundary** (lint/CI rules whose bypass would defeat an ADR constraint or a security control); changes CI permissions or supply-chain policy | HIGH |
| adds or changes application behaviour, schemas without the properties above, non-sensitive APIs, configuration and startup/env validation, build/tooling, tests, non-boundary lint rules | MEDIUM |
| text, copy, documentation, isolated presentational UI, refactor with no behaviour change and no security surface | LOW |

### 3.3 Flags (modify the workflow without raising the level)

| Flag | When | Effect |
|---|---|---|
| **S — security-flagged sub-surface** | a LOW/MEDIUM task contains a specific security property (e.g. "error output must not leak secret values", "fail closed on missing config", "no values in `.env.example`") | **MEDIUM:** one of the two agent slots MUST be `agent-skills:security-auditor` scoped to the sub-surface, launched after S7c (if used) and before S8 (the other slot MAY stay unused — budgets are maxima; S7c is the default use of a free slot). **LOW:** the budget becomes 1, used only for that scoped security agent. In both cases the plan §8 threat model covers the sub-surface, the S8 feedback notes MUST name it, and the validation set MUST contain a negative probe for it |
| **G — phase gate** | the task is the phase's **measured output**, or the phase names the task's acceptance as its **exit gate** (e.g. "ledger concurrency test green in CI") — **not** an item of the generic infrastructure definition-of-done list that every task of the phase appears in | final code inspection uses Astra HIGH regardless of level (§8.3) |
| **D — new dependency** | the task adds a package or changes a pinned version (a `catalog:` reference to an already-catalogued package is not a new pin and does not set D) | plan review required (§8.2); **dependency discipline** (`code-review-and-quality`): one dependency (or one related group) per change; exact pin; changelog/migration notes read for the pinned version; lockfile diff reviewed, never hand-edited; `pnpm why <pkg>` (or equivalent) shows only the intended importers; advisory check of the exact pin (B14) and release-age policy respected |
| **X — cross-repository** | the task edits more than one repository | each repository gets its own branch/PR and its own inspection base |

---

## 4. Agent-budget rules (no agent explosion)

### 4.1 Budgets

| Level | Specialist agents (total for the task, all stages, including every agent of a §4.3 run and every persona/doubt/fan-out launch) |
|---|---|
| LOW | 0 (1 when flag S applies) |
| MEDIUM | max 2 |
| HIGH | normally max 4; a written §4.3 run may extend the task total to 8 |
| CRITICAL | normally max 4; up to 4 more, one per concrete written unresolved question that no existing artefact answers; ceiling 8 per task |

Beyond 8 agents in any task, or beyond the row's cap without the written justification the row names, requires an owner statement quoted in the log. `budget=` in the command may lower a cap or raise it up to 8.

Counting rule: every `Agent` launch counts; every agent inside a `Workflow` run counts; a `Workflow` run counts its agents against the same budget (it is inside the number, not in addition to it); an `Agent` launch of a persona counts 1, a `/ship`-style fan-out counts 3, `/webperf` counts 1, a fresh-context doubt review counts 1; `/review`, `/test` and `/code-simplify` run their skill in the host context and launch no agent (0 slots — they are host self-review, not the S7c pre-inspection). Re-sending a message to an existing agent does not count only when it clarifies the **same** assignment on the **same** artefact in the **same** stage; a new assignment, artefact set or later stage sent to an existing agent counts as a launch and needs its own roster line. A read-only `Explore` launch counts as one agent.

### 4.2 Launch discipline

- An agent is launched only with: a one-line assignment, the files/questions it must cover, the artefact it must return, the stage, and the reason a host-side read is insufficient.
- The roster (S3) records, for each plausible agent that is **not** launched, why not. "Capacity is available" is never a reason to launch.
- Agents never receive authority: they report; the host classifies (§5.2) and decides. Personas do not invoke other personas (platform-enforced); orchestration depth is at most one.
- Agents work read-only unless the plan names a file set they may edit in an isolated worktree.
- **After every agent or workflow run** the host runs `git status --porcelain --untracked-files=all` in both repositories and the integrity/machine-drift checks (Annex L §L4 B15/B16) before continuing; any change caused by an agent is reverted, recorded in the log as an agent deviation, and is a reason not to launch that agent type again in the task.

### 4.3 Attack matrices and red-team workflows

A large attack matrix (`Workflow` with adversarial lenses/verifiers) is allowed only when **all three** hold and are written in the plan or review log **before launch**:

1. the task is genuinely security-sensitive (HIGH or CRITICAL, or an S-flagged sub-surface that the owner named as an attack surface);
2. a specific **target surface** is identified (e.g. "specifier forms that bypass the import-boundary rule", not "find anything");
3. the scope is written: lenses, candidate cap, verifier count, time cap, and what happens with the result.

Fan-out pre-check (from `references/orchestration-patterns.md`), answered in writing before any parallel launch: can every sub-agent run at the same time without ordering issues; does each produce a different *kind* of finding rather than the same finding from another angle; does the merge fit in the host's context; is the wall-clock gain real. Any "no" → a single agent or none.

Caps (MUST): one run per task; at most 8 agents per run; the run's agents count against the §4.1 budget and the task total including the run never exceeds 8; a second run, or any number above these caps, requires an owner statement quoted in the log. Verified findings enter §5.2 classification like reviewer findings, each with a root class.

### 4.4 Variant-discovery stop rule

Every accepted finding carries a **root class** (a short label naming the mechanism, e.g. `specifier-syntax-variant`, `cjs-loader-surface`, `nested-destructuring`) in the Annex C disposition table. If agents or reviewers return a finding whose root class equals the root class of a finding fixed in either of the two previous fix sets, or if a fix set would be the third one carrying the same root class, the host MUST stop patch-by-patch work, write a root-cause/design analysis (what contract would close the class), and either implement the redesign as one authorised change or escalate to the owner (§5.4). The host checks the root-class column before launching any fix and records the check in the fix entry.

---

## 5. Review-loop limits

### 5.1 Normal shape and caps

```
PLAN → independent plan review (if §8.2 requires) → IMPLEMENT → VALIDATE
     → independent code inspection → FIX valid (class A) findings → one fresh final verification
```

| Loop | Automatic cap (per task) | Beyond the cap |
|---|---|---|
| Plan review rounds | 3 completed rounds (counter `plan round n/3` in every log entry); at most **one** may be provisional (§8.5) | owner decides: another round, accept with documented residual, or redesign — never by dropping a §8.3 review |
| Code inspection rounds | initial inspection + 2 fix-and-re-inspect rounds = 3 fresh inspections (counter `inspection n/3`); at most **one** may be provisional (§8.5) | owner decides — never by dropping the §8.3 final review |
| Fix sets without a new inspection | 0 — every accepted fix set gets a fresh inspection before the PR can be ready | — |

Counting rules:

- A round counts when the runner result has `status == completed` and a verdict (APPROVED / REVISE / BLOCKED).
- The cap counts rounds **per task, not per reviewer session**: a new session (model change via `reviewer=` or §8.5, or a fresh session after a failed round — the runner accepts `--resume` only from a successful result, and the host MUST NOT resume the last successful result once a newer round has failed) continues the same counter.
- **BLOCKED** is a completed turn reporting missing evidence: the host MAY re-submit once with the missing evidence; a second BLOCKED on the same plan or snapshot goes to the owner.
- **Operational failures** (§8.4: usage limit, `turn.failed`, missing verdict, timeout, malformed result) do not count as rounds. A single failure is retried once in a fresh session, decided by the host and recorded (both artefact directories named); a second consecutive failure in the same stage establishes unavailability (§8.5). No further retry of that model without an owner statement.
- **The review §8.3 requires is never cap-blocked:** once the required reviewer is available, its plan review and/or final inspection is permitted even at counter 3/3, counted and logged as `final (post-cap)`; its REVISE goes to the owner per §5.3.
- **One reviewer home per task:** every round — `--resume` rounds, provisional rounds and the post-cap final review included — runs under the reviewer `CODEX_HOME` recorded in the log header (Annex L §L3); a session created under any other home is not resumable, does not count as a round, and its result is void.
- The claudex-loop skill tunables `MAX_ROUNDS` / `MAX_FIX_ROUNDS` / `MAX_INSPECTION_ROUNDS` are host-enforced values, not runner behaviour; under this standard they are 3 / 2 / 3 and override the skill defaults (5 / 2 / 2). The review-log header states them.

### 5.2 Finding classification (mandatory before any fix)

| Class | Meaning | Automatic action |
|---|---|---|
| **A** | valid defect inside the current contract (plan + task file + referenced architecture) | eligible for an in-scope fix within §5.1 caps and the §4.4 root-class check; **every class-A fix ships with a Prove-It probe** (`test-driven-development`): a test or probe that fails before the fix and passes after it, recorded with its command and both results |
| **B** | unsupported behaviour outside the current contract (the contract never promised it) | no fix; record as residual (with owner + expiry when it is a tracked exception) or as a contract question for the owner |
| **C** | a different security/task class owned by another task | no fix; hand off with a written acceptance criterion to the owning task (Annex L §L7 register); record in the log and PR |
| **D** | false positive / unsupported finding | no fix; record the evidence that refutes it |

Every finding gets an ID (`R<n>` continuing across rounds), severity, class, **root class**, evidence and disposition in the review log. Persona findings (Critical/High/Medium/Low/Info) and doubt-review findings (contract misread / actionable / trade-off / noise) are mapped into the same table by the host. The host-authored `--feedback` file for the next round contains exactly these dispositions. A **medium/high security-sensitive** finding dispositioned B, C or D needs an owner acknowledgement quoted in the log before the task can reach COMPLETE (§6.6, §9.8).

### 5.3 What "one fresh final verification" means

After the last accepted fix set: re-run the affected validation checks, run the full baseline set once, run `check` on the plan when an external plan approval exists (§8.2), and launch **one** fresh inspection over the **full diff against the pre-build base** (the runner always supplies it) with the reviewer §8.3 requires. The feedback notes state that it is the final verification, list the fixed finding IDs with their commits and root classes, what must be confirmed, and what is out of scope — they never narrow the inspected diff. Its APPROVED result is the merge-readiness evidence. Its REVISE result goes to the owner with A/B/C/D classification — no automatic further round. A provisional review (§8.5) is never the final verification. An inspection is the final verification when the host declares it in the feedback notes; the round at counter 3/3 MUST be declared final, an earlier round MAY be. A REVISE on an undeclared round follows S8 (fix class A, re-inspect fresh) while the counter allows; a REVISE on a declared final round goes to the owner.

### 5.4 Root-cause rule

When §4.4 fires (same root class after two correction rounds, or a third fix of one root class):

1. classify it as a design/root-cause problem (record the class, the variants, the mechanism);
2. stop automatic patching;
3. produce a root-cause/design analysis with at most two options (narrow the contract / redesign the mechanism) and a recommendation;
4. wait for the owner's decision; final state `BLOCKED — OWNER DECISION REQUIRED`.

---

## 6. Security principles (mandatory for every task)

1. **Fail closed** where the architecture requires certainty: unknown input, unsupported form, missing configuration → reject, never "allow by default".
2. **Least privilege** for agents, CI, tokens, reviewer sandboxes and generated code.
3. **No secrets in source, logs, PR bodies, review artefacts or reports.** `.env.example`-style files carry key names only. Validation includes the secret-pattern scan of the diff (Annex L §L4 B17).
4. **No production access** (databases, services, dashboards, real provider keys, including read-only access) without an explicit owner authorisation naming the system.
5. **No deployment** without explicit owner authorisation.
6. **Security-sensitive medium/high findings block merge** until resolved (class A, fixed and re-inspected) or formally dispositioned (class B/C/D **with an owner acknowledgement quoted in the log**). A task with such a finding and no acknowledgement ends `BLOCKED — OWNER DECISION REQUIRED`, listing the finding IDs and proposed dispositions.
7. **Validation cannot be weakened to obtain green.** Observable definition (`constraint-driven-development`, "five moves that lower the bar"): a threshold lowered or a check removed from the set; a test made easier (`.skip`/`.todo`, a deleted test file, an assertion removed from a test that stays); a checker silenced (new `@ts-ignore`, `eslint-disable`, `istanbul ignore`, `nosemgrep`, `gitleaks:allow` or equivalent); unfinished work (a stub that throws, an empty `catch`, a `TODO` standing where the implementation should be); a new exception nobody discussed. Any of these in a task diff is reported, never merged silently; tests, lint rules, acceptance criteria and architecture constraints change only by an authorised plan change. Repository-level mechanical enforcement (floor guard, CI) is a P1-T04 deliverable (Annex L §L7).
8. **No invented business rules**: a missing rule is an owner question, not an assumption.
9. **Architecture and task contracts override agent creativity**: ADRs, task files and the approved plan win over any agent, persona, skill or advisory suggestion.
10. **Scratch and red-team artefacts stay outside product repositories** unless the plan names them as deliverables; temporary probe files are deleted before validation evidence is recorded.
11. **Reviews run only in the dedicated reviewer home and every Codex call goes through the approved claudex runner.** The reviewer home (`C:\Users\Monster\.codex-review`, Annex L §L2/§L3) carries no MCP servers, local plugins, `notify`, hooks or trusted projects, and every account-level connector is disabled by config (`[plugins."…"] enabled = false`, `features.apps = false`); S1 proves this with the reviewer-isolation preflight (§L3a) and records the result in the Intake Record; a failed preflight blocks every review of the task, and a review launched under the normal `~/.codex` is a §6 violation whose result is void — there is no fallback to the normal home. The read-only shell sandbox does not restrict external MCP side effects, which is why the surface is removed rather than sandboxed. Direct `codex exec` / `codex review` invocations (including the cross-model step of `doubt-driven-development`) are prohibited: they carry no approval binding, artefact directory or snapshot fingerprint.
12. **No hooks that write into repositories or mutate files during reads.** The `agent-skills` hooks `simplify-ignore` (rewrites files on `Read` with placeholders) and `sdd-cache` (writes `.claude/sdd-cache/` into the project) are never enabled for these repositories; any hook proposal is an owner decision under §1.
13. **A reviewer or model limit never silently downgrades the security bar** (§8.5): a fallback changes who works or who reviews provisionally, never which final review or which gate is required.
14. **No web or network tools during private-code review.** The isolated Codex reviewer still exposes the built-in `web__run` capability because the installed Codex version (0.154.0) provides no verified feature flag that removes it; no unsupported global configuration hack is attempted to remove it. Policy: a review of private repository code MUST NOT use web or network tools unless the task contract explicitly authorises external research; every reviewer prompt the host authors (plan §0 authority block, every `--feedback` file, every inspection note) states this restriction verbatim ("Do not use web or network tools; this is a private-code review; cite only repository content"); use of external web during a private-code review without that authorisation is a review-protocol violation recorded in the log; the round's findings that depend on web evidence are **not accepted on that evidence** — the host re-examines each one against repository content alone and classifies it A/B/C/D on that basis (a security-sensitive finding that cannot be refuted from repository evidence is treated per §6.6 and §9.8, never closed as D merely because of the violation).

---

## 7. Git / GitHub contract

### 7.1 Default lifecycle

```
main → task branch → implementation commits → validations → independent inspection
     → commit/push → draft PR → final inspection → READY FOR OWNER MERGE → STOP
```

| Item | Rule |
|---|---|
| Base | the `origin/<default>` tip after `git fetch --prune`, recorded together with the merge commit of every dependency task, each verified as an ancestor of that tip (`git merge-base --is-ancestor`); local default branches are not trusted and are not advanced silently |
| Branch name | code: `feat/<task-id-lowercase>-<task-file-slug>` (e.g. `feat/p1-t02-config-env-port`); documentation: `docs/<slug>`; fix-only follow-ups: `fix/<task-id>-<finding-id>` only when the owner asks for a separate branch |
| Commits | conventional prefix + task id in scope + the plan step, e.g. `feat(p1-t02): step 3/6 — …`; one commit per plan step, per S7b simplification set or per authorised fix set; message lists the finding IDs and root classes it closes; attribution trailer as configured; the builder model that produced the commit is recorded in the checkpoint (§12), not in the message |
| Push | task branch only; after validation is green (a WIP push is allowed only when the PR is a draft) |
| PR | draft on first push; body template Annex D §D2; Ready for Review **only** after the final inspection required by §8.3 is APPROVED (provisional reviews keep it draft) — or, for a LOW task exempt from inspection by §3.1/§8.2/contract, after the logged "no inspection required" entry — **and** the S9 head/snapshot check (exempt path: bound to the S7 evidence) passes |
| Never (by default) | merge; force-push; delete branches; deploy; rewrite published history; tag releases; change repository settings |
| Owner | performs the final merge unless a written authorisation names Claude for a specific PR |
| Known limitation | GitHub branch protection is not available on the free private plan; the "owner merges" rule is procedural, so the PR body states it explicitly |

### 7.2 Cross-repository and documentation changes

Documentation repositories follow the same branch/PR flow. A task that edits both a code and a documentation repository (flag X) opens one PR per repository and records the dependency between them in both bodies. Task files, ADRs and handoff documents in the documentation repository are edited only when the task contract or the owner says so; new ADRs match the repository's existing convention (location, numbering, headings — the `documentation-and-adrs` reference MAY be consulted for format only; it is not a §1 method skill and adds no step).

---

## 8. Reviewer / model routing (use models economically)

### 8.1 Roles

| Model | Role | Never used for |
|---|---|---|
| Claude Fable 5.1 HIGH (`claude-fable-5-1`) | primary planner/builder/orchestrator | independent review of its own code |
| Claude Opus 5 HIGH (`claude-opus-5`) | **builder fallback** when Fable is exhausted or operationally unavailable (§8.5); continues the same task from the checkpoint | independent review; replacing Fable while Fable is available unless the owner names it with `builder=` (recorded) |
| Claude specialist personas (`agent-skills`, same model family, `Agent` tool) | targeted internal expertise within §4 budgets | approval verdicts |
| Codex **GPT-5.6 Sol** HIGH (`gpt-5.6-sol`, `--effort high`) | ordinary independent technical review: LOW/MEDIUM plan reviews and code inspections; **provisional** reviews of HIGH/CRITICAL when Astra is unavailable (§8.5) | final HIGH/CRITICAL verdicts; flag-G final inspections |
| Codex **GPT-6 Astra** HIGH (`gpt-6-astra`, `--effort high`) | HIGH/CRITICAL security reviews; concurrency/inventory correctness; authentication/authorization; architecture gates; phase-critical final inspections (flag G) | trivial work "because it is available" |
| Jev (advisory routing layer, §8.6) | routing recommendations in shadow mode | any decision, approval or waiver |

### 8.2 When a plan review is required

Plan review is required when any holds: level HIGH or CRITICAL; flag D (new dependency) or flag G; the task contract requires "plan review APPROVED"; the plan proposes a structure not already fixed by an ADR or the task file. Otherwise (LOW/MEDIUM without those conditions) the host's self-review (round 0) suffices and the log says so.

### 8.3 Model selection per stage (deterministic)

| Level / flag | Plan review | Intermediate re-inspections | Final inspection |
|---|---|---|---|
| LOW / MEDIUM (review required by contract or §8.2) | Sol | Sol | Sol |
| LOW / MEDIUM + G | Sol | Sol | **Astra** |
| HIGH | **Astra** | Astra | **Astra** |
| CRITICAL | **Astra** | Astra | **Astra** |

Owner `reviewer=` overrides upward at any time; downward only with a recorded owner decision. A model's first use on the machine is an accepted risk by default and does **not** justify routing a task upward pre-emptively.

### 8.4 Availability and failure handling

- A model id listed in the local catalogue (`codex debug models`; the Claude model list) is not proven runnable; the first real call with a model is its proof. The Intake Record marks a never-used model as "first use".
- Requested and observed model identity are recorded separately (runner result); an unknown observed identity stays unknown.
- Usage-limit or CLI failures (`turn.failed`, missing verdict, timeout, malformed result, "usage limit reached" from either provider) are **operational events**: report them, do not count a round, retry once per §5.1, and treat the model as unavailable only under the evidence rule of §8.5. No silent model or provider substitution outside §8.5.
- Every reviewer launch passes `--artifacts <task dir>/artifacts`, repeats the first round's `--model`/`--effort` on `--resume`, and keeps the full runner stdout in a file; verdicts are read from `result.json` (`status`, `exit_code`, `response.verdict`, `snapshot`).

### 8.5 Quota-aware routing and fallback policy

The workflow MUST NOT stop merely because one preferred model reaches a usage limit; it MUST NOT lower any gate because of it.

**Unavailability is an evidenced state, never an assertion.** A model is `unavailable` for a task only when the log quotes (a) a runner `result.json` with `status != completed` whose `stderr.txt` / `stdout.txt` contains the provider's usage-limit or quota message verbatim (for the Claude builder: the limit message shown by the exhausted session, relayed by the owner in the `resume=` command and quoted in the log by the resuming session as the first entry of the fallback), or (b) two consecutive operational failures (§8.4) of fresh sessions of that model in the same stage, each with its artefact directory named. A single timeout, `turn.failed` or malformed result is a retry under §5.1, not unavailability. The log entry that declares unavailability records the retry window the provider reports (or `unknown`) and, for Astra, sets `Pending Astra gate: <HEAD>` in the checkpoint at the same moment. The evidence comes from runner artefacts produced under the reviewer home; retries and the provisional path run under it as well.

| Situation | Action | What stays fixed |
|---|---|---|
| **Builder (Fable 5.1) unavailable** | 1. the fallback starts from the checkpoint written at the last stage boundary (§12), which therefore always exists; 2. the Opus session begins with the §12 resume procedure: any uncommitted diff found on disk is saved to the task directory as `unattributed (fable, mid-<stage>)`, every validation row is marked stale, and the diff is re-validated before anything is built on it; 3. continue the **same** task with **Claude Opus 5 HIGH**; the builder does not change again within a stage, and returning to Fable is allowed only at a stage boundary and is logged; 4. log "builder: opus-5 from stage Sx, reason, timestamp". The task is never restarted from scratch because the builder changed; the plan, its approval and the inspection base remain the same. If Opus is also unavailable, the task ends `INCOMPLETE — TECHNICAL FAILURE` naming the checkpoint path; no third builder and no provider change without an owner `builder=` | risk level, flags, budgets, review caps, reviewer routing, owner gates |
| **Sol (ordinary reviewer) unavailable** | the single §5.1 retry — one fresh session, after the provider-stated window when one is reported — decided by the host and recorded; no further host-decided retry exists: if the window is unknown or that retry fails, the owner chooses wait or `reviewer=gpt-6-astra` (an upward substitution, recorded) | everything else |
| **Astra unavailable — and Astra is the required reviewer** (HIGH, CRITICAL or flag G) | the task MAY continue through S6–S7. For HIGH/CRITICAL, Sol HIGH MAY perform **one** **PROVISIONAL** plan review and **one** provisional inspection (same runner, same artefacts, logged as `provisional`, counted as rounds, §5.1); class-A findings from them are fixed normally; a provisional Sol plan approval satisfies the S6 entry for HIGH; for CRITICAL the S5→S6 checkpoint message MUST state "plan approval PROVISIONAL (Sol) — Astra plan review pending" and S6 starts only on an owner statement that names this. For LOW/MEDIUM + G, Sol's plan review and intermediate inspections are final per §8.3 (not provisional) and only the final inspection waits. **But:** the PR stays DRAFT; the task MUST NOT become Ready for Owner Merge; the **pending Astra gate comprises every §8.3 review that names Astra and that Astra has not given** — for HIGH/CRITICAL a runner `review` of the approved plan (same plan SHA, same `--repo` as S5) **and** a fresh `inspect` of the checkpointed HEAD; for LOW/MEDIUM + G only the fresh `inspect` — and every review in the gate must be APPROVED before the PR leaves DRAFT; when Astra is available they run against the exact checkpointed snapshot (same HEAD, same base; any edit in between → new checkpoint and the Astra inspection covers the new HEAD), even at counter 3/3 (§5.1) | the final reviewer (§8.3), §6, §9 gates |
| **Astra unavailable — and Astra is not the required reviewer** (LOW/MEDIUM without G) | no effect: Sol's reviews are final per §8.3; the provisional path and the pending gate do not apply | everything |
| **Both Codex models unavailable** | if S6's entry condition is already satisfied (an approved plan exists, or §8.2 requires no plan review for this task): finish S6–S7, write the checkpoint, report `BLOCKED — OWNER DECISION REQUIRED` naming the pending review gate and the retry window. Otherwise — every HIGH/CRITICAL task and every LOW/MEDIUM task whose plan review is required (§8.2, including the Larante Phase 1 contract minimum of Annex L §L5) and not yet approved — stop at S5 with no implementation, write the checkpoint, report `BLOCKED — OWNER DECISION REQUIRED` naming the pending plan review | — |
| **Jev unavailable** | S3 uses the deterministic tables only; the Jev shadow record says `unavailable`; no workflow failure | everything |

Reporting: a task that reaches S10 with a pending Astra gate ends `BLOCKED — OWNER DECISION REQUIRED` (decision: when to run the pending Astra reviews), never `COMPLETE`. Every fallback event is a line in the log and in the completion report (builder used, reviewer used, provisional/final status).

### 8.6 Jev routing policy (advisory layer, interface only)

**Status:** Jev is **not installed or connected**. This section defines the interface and the policy so that a future integration is bounded before it is reviewed; the integration itself (method, permissions, data exposure, required software) is a separate owner approval (§1 "No new software").

**Position in the routing order:**

```
DETERMINISTIC HARD RULES (§3.2 triggers, §3.3 flags, §4.1 budgets, §5.1 caps, §6, §8.3, §9 gates)
   → JEV ROUTING ADVICE (recommendation + confidence; shadow mode)
      → DWS HOST DECISION (records advice, applies the tables, may raise, never lower)
         → CLAUDE / AGENTS / REVIEWER (execution under §2)
```

**Jev MAY recommend:** a level (LOW / MEDIUM / HIGH / CRITICAL); relevant specialist personas; whether Sol review is sufficient; whether Astra is required; whether an owner checkpoint is appropriate; a confidence level.

**Jev MUST NEVER:** reduce a deterministic minimum risk level; waive a security requirement (§6); waive a required Astra review (§8.3); approve merge; override owner or business decisions; launch agents, reviewers or tools; write to repositories, plans or logs.

**Interface (advisory request/response; no repository content leaves the machine unless the integration review approves it):**

```
JevRoutingRequest  = { task_id, contract_summary (Goal/Scope/Files allowed/Security impact — text only),
                       deterministic_level, deterministic_flags, budget_table_version: "DWS-1 r2" }
JevRoutingResponse = { recommended_level, recommended_agents[], sol_sufficient: bool,
                       astra_required: bool, owner_checkpoint_recommended: bool,
                       confidence: 0.0–1.0, rationale (≤ 5 lines), jev_version }
```

Any field that would lower the deterministic level, drop a required reviewer or waive a gate is recorded and ignored.

**Shadow mode (mandatory for at least the first 10 Jev-enabled tasks; the owner's target window is 10–20):** Jev is requested exactly once per task, at S3; the host records the response in the task directory (`<TASK-ID>-JEV-SHADOW.md`: request digest, response, deterministic decision, differences); the workflow proceeds on the deterministic tables only — during shadow mode Jev advice changes no decision, not even upward ("may raise" in the routing order applies only after shadow mode ends); at S10 the host appends the actual outcome (final level, agents actually used, reviewer actually required, reviewer findings by class, owner gates hit) and a per-field agreement mark. The comparison feeds the routing-accuracy register (Annex L §L7 H5, which carries the task counter); shadow mode continues until the owner records a decision to end it after reviewing the register — at the earliest after task 10 and, if no decision is recorded, indefinitely — and ending it never removes the "never" list above.

**Unavailability:** if Jev is absent, unreachable or returns an invalid response, S3 proceeds on the deterministic tables with the shadow record set to `unavailable`; no workflow failure, no retry loop.

---

## 9. Owner decision gates (the only places the protocol stops for input)

The protocol stops and asks **only that question** when:

1. the task contract is ambiguous in a way that changes the deliverable, needs a business rule that no document states, or needs a capability not in Annex L §L2;
2. a CRITICAL task reaches the mandatory S5→S6 checkpoint;
3. a reviewer finding is class B or C and closing it would change scope, or an A-finding needs a contract change to fix;
4. a §5.1 cap is reached without approval, or §5.4 triggers;
5. a reviewer/model event that §8.5 does not resolve automatically: a Sol retry that failed or has no known window, both Codex models unavailable, or a pending Astra gate at S10 — the owner chooses retry, wait or an upward substitution; **or a failed reviewer-isolation preflight (S1, Annex L §L3a)** — the owner restores the reviewer home (re-login, configuration, Annex L §L7 H7) or stops the task; the task's reviews stay blocked until the preflight passes and are never run under `~/.codex`;
6. an action would be irreversible or outward-facing beyond §2.2 (merge, deploy, production access, publishing, deleting);
7. the owner's `level=` is below a classifier CRITICAL or HIGH-security trigger (§2.1);
8. a medium/high security-sensitive finding needs a B/C/D disposition (§6.6).

Everything else — the builder fallback to Opus 5, the single automatic Sol retry, the provisional Sol path while the Astra gate stays pending, Jev unavailability and the recording of Jev advice (§8.5, §8.6) — is decided by the host under this standard, recorded in the log, and reported at S10.

---

## 10. Completion report standard

Every task ends with one compact report (Annex D §D1) containing, in this order: task; risk level (+ flags, deciding triggers); Jev shadow recommendation and agreement (or `unavailable`); agents actually used and why (and the roster of agents not used); builder(s) used and any fallback event; files changed; "NOTICED BUT NOT TOUCHING" register; validations (table with exit codes); security checks; review rounds (plan + code, model, artefact ids, counters, provisional/final status); final reviewer verdict (quoted summary); commit(s); PR (number, state, head, inspected HEAD); deferred findings and owning task (Annex L §L7); production/deployment status; final state.

Final state is exactly one of:

```
<TASK-ID> STATUS: COMPLETE — READY FOR OWNER MERGE
<TASK-ID> STATUS: BLOCKED — OWNER DECISION REQUIRED
<TASK-ID> STATUS: INCOMPLETE — TECHNICAL FAILURE
```

`COMPLETE` requires: the final inspection required by §8.3 APPROVED (never a provisional one) or, for a LOW task exempt from independent inspection by §3.1, §8.2 and its contract, the log entry "no inspection required" with the reason; S9 head/snapshot check passed; PR Ready for Review; both repositories clean; checkpoint record final; no unrecorded deviation; **no medium/high security-sensitive finding dispositioned B/C/D without an owner acknowledgement quoted in the log**; the Definition-of-Done self-check (Annex D §D1) answered. `BLOCKED` names the single decision needed (for §9.8: the finding IDs and proposed dispositions; for a pending Astra gate: the checkpointed HEAD awaiting review). `INCOMPLETE` names the failing step and the evidence.

Reports are written in the language of the owner's command; identifiers, commands and quoted reviewer text stay verbatim.

---

## 11. Amendments

This standard changes only by an owner-approved PR that bumps the version in the header and in Annex L §L1; the user-skill copy is refreshed in the same change (hash recorded in the PR body). Task-level deviations are recorded in the task's review log and completion report, never by editing this document.

Draft history:

- **r0** (2026-09-22) written by the host.
- **r1** (2026-09-22): reviewed by a bounded 2-agent workflow (`wf_09ac488a-a97`: one standard reviewer, one blind P1-T02 router) — 24 findings (F01–F24) applied, plus the router's wording ambiguities (flag G scope, closed HIGH list, S-agent stage, B9 definition, first-use rule, Files-allowed interpretation).
- **r2** (2026-09-22, owner decisions on the Agent Skills integration proposal): §0 quota row; §1 personas by stable plugin name (no local copies), method skills keep/adapt lists with stage bindings, "not used as orchestrators" list, hooks never wired, Jev as advisory, `builder=` and `resume=` qualifiers (§2.1); §2.2 fallback/provisional authority; §2.3 S3 Jev shadow record and availability, S4 round-0 doubt + five-axis self-review, S6 incremental/TDD discipline and NOTICED register, S7 stop-the-line, new S7b conditional simplification and S7c host pre-inspection, S8 provisional path, S9 change summary and "final, not provisional" condition, checkpoint update at every stage; §2.4 checkpoint and Jev records; §3.2 "floor no advice can lower"; §3.3 flag D dependency discipline, flag S threat-model tie-in; §4.1 counting of persona/fan-out/doubt launches; §4.2 depth ≤ 1; §4.3 fan-out pre-check and "target surface"; §5.1 provisional rounds count, §8.5 cross-reference; §5.2 Prove-It probe for class A, persona/doubt finding mapping, exceptions with owner + expiry; §5.3 provisional never final; §6.7 five moves, §6.9 advisory suggestions, §6.11 runner-only Codex, new §6.12 hooks and §6.13 no silent downgrade; §7.1 builder recorded in checkpoint, provisional keeps draft; §7.2 ADR convention; §8.1 Opus 5 fallback row, Sol provisional role, Jev row; §8.4 both providers; new §8.5 quota-aware routing and fallback; new §8.6 Jev routing policy (order, may/never, interface, shadow mode, unavailability); §9.5 rewritten, closing sentence; §10 new report fields and COMPLETE conditions; new §12 checkpoint/resume contract; Annex A/B/C/D fields; new Annex E (checkpoint record, Jev shadow record); Annex L2 agent-skills and Jev rows; Annex L4 B18 note; new Annex L7 handoff register (T04: floor guard/CI enforcement + R17; T07: CLAUDE.md consolidation).
- **r2 review** (2026-09-22, owner decision D12): bounded 2-agent workflow `wf_184e102f-991` (one r2 reviewer, one blind P1-T02 router; no attack matrix) — 18 findings (G01–G18) applied: evidenced unavailability (§8.5); provisional rounds ≤ 1 and the §8.3 review never cap-blocked (§5.1); pending Astra gate = plan review + inspection, CRITICAL provisional statement, HIGH/CRITICAL stop at S5 when both Codex models are unavailable (§8.5, S6 entry); HIGH roster arithmetic — one of Plan/doubt + the S7c fan-out (§3.1, S7c); `/review`, `/test`, `/code-simplify` launch no agent (§4.1, S7c); doubt-driven degraded form and one-cycle limit (§1, S4); re-send rule narrowed (§4.1); builder fallback from the last stage checkpoint, unattributed diff handling, Opus-exhausted end state, no ping-pong (§8.5); resume procedure with contract SHA, extra-commit mapping, counters and `check` (§12, §7.1 step numbers); §9.5 and closing sentence rewritten; Jev once per task and no upward change in shadow mode (§1, §8.6); runner `--resume` wording (§5.1); S1 persona check (§2.3); D11 recorded (Annex L §L5); code-simplification adaptation (§1); Opus `builder=` exception (§8.1); shadow-mode stop condition (§8.6); final-verification declaration (§5.3). Router clarifications applied: a dry run writes nothing (§2.1); S7c/S-agent order and default slot use (§3.3, S7c); catalog references do not set D (§3.3); Astra-not-required row (§8.5); B9 compares to the Intake-Record docs commit (Annex L §L4); smoke environment supplied inline (Annex L §L4); Claude availability by successful turn (S1); log-header caps from the first DWS task (Annex L §L5); tool-surface acceptance rule (§6.11, Annex L §L7 H6).
- **r2 reviewer home** (2026-09-22, owner decision "option C"): all Codex reviews run under the dedicated `C:\Users\Monster\.codex-review` home supplied per process (§1, §5.1, §6.11, §8.5, §12, Annex A/C/E, Annex L §L2/§L3/§L3a); S1 reviewer-isolation preflight replaces the tool-surface classification and is a blocking gate with no fallback to `~/.codex`; H6 closed, H7 added.
- **r2 final bounded review** (2026-09-22, owner instruction "formalize r2"): §6.14 web/network residual policy added; bounded 2-agent workflow `wf_6be186c7-d07` (governance lens + security/fallback/isolation lens; no attack matrix) — 18 findings, 16 class A applied in one correction pass (§9.5 preflight-failure gate; §6.14 web-dependent findings re-classified on repository evidence instead of closed as D; §L3a/§6.11 wording on account-level connectors; preflight script fail-open fix — an `enabled = false` line is now required inside every `[plugins."…"]` block; §8.5 Astra row split HIGH/CRITICAL vs LOW/MEDIUM+G; §8.5 Sol row = the single §5.1 retry; Claude-builder limit evidence relayed by the owner; §3.2 Jev qualifier; dry run requests no Jev; §7.2 ADR reference not a method skill; S1 hook check; SKILL.md runner facts and `budget=` path) and 2 class C recorded as owner carry-ins (Annex L §L7: H1–H3 not yet in P1-T04's Acceptance; H4 outside P1-T07's contract).
- **Independent GPT-6 Astra HIGH document review, round 1** (2026-09-22, runner `review` under the isolated reviewer home, artefact `claudex-kb0ltgja`, session `01a0c9c3-b5bf-7fa0-9207-5a541717fcbd`, input SHA `7e215867…`): REVISE — 7 findings, all class A, applied: R01 preflight script fails closed when a CLI listing fails or is unrecognised; R02 both-models-unavailable branch requires S6's entry condition (approved plan or no review required) before any implementation; R03 preflight validates `sandbox_mode` / `approval_policy` at the root table only and rejects `[profiles]` / root `profile` keys; R04 checkpoint rewritten after every counted operation and counters reconciled from artefacts and log on resume; R05 explicit transitions for review-exempt tasks (`check` only with an external approval; LOW without inspection → "no inspection required" recorded); R06 `builder=codex` restricted to contracts without a Codex-inspection requirement, the Claude inspector then being the recorded §8.3 final reviewer; R07 base = the `origin/<default>` tip with each dependency merge verified as an ancestor.
- **Astra round 2** (resume with dispositions, artefact `claudex-u_do_hzb`, input SHA `51c6dcc0…`): REVISE — R01, R02, R04, R06, R07 confirmed resolved; R03 and R05 partially fixed. Host fixes applied afterwards (**not yet independently verified**; the owner's one-verification cap is spent): R03 → the preflight validates the reviewer `config.toml` with TOML-aware parsing (root keys, prohibited tables incl. any `profiles` table under any spelling, plugin blocks) instead of text matching; R05 → the inspection-exempt LOW path carried through S8 (explicit skip), S9 (head/hash check bound to the S7 evidence), §2.2, §7.1, §5.3 (`check` only with an external approval) and Annex D1.

---

## 12. Model-checkpoint / resume contract

Each task MUST preserve enough state to resume with another capable model without reconstructing the project from conversation history. **Git, the task files, the review artefacts and the validation evidence are authoritative; conversation memory alone is not.**

**Checkpoint record** (`<task dir>/<TASK-ID>-CHECKPOINT.md`, Annex E §E1), rewritten by the host at the end of every stage, **after every counted operation inside a stage** (each completed review round, each fix set, each agent or workflow launch), before any builder or reviewer change, and at S10. Required metadata:

| Field | Source of truth |
|---|---|
| task ID | owner command |
| authoritative task contract (path + SHA256) | documentation repository |
| risk level and flags (+ deciding triggers; Jev shadow reference) | Intake Record |
| branch | `git branch --show-current` |
| base | recorded `origin/<default>` SHA |
| current HEAD (+ `git status --porcelain` digest; uncommitted diff saved to the task dir when non-empty) | git |
| files changed (vs base) | `git diff --name-status <base>...HEAD` + untracked list |
| completed stages (with timestamps and counters) | review log |
| remaining stages (next stage first) | this standard §2.3 |
| validation results (table id → exit code → evidence file) | scratchpad evidence |
| findings and dispositions (ID, class, root class, state) | review log Annex C table |
| reviewer/model used per round (requested vs observed; provisional/final) | runner `result.json` files |
| reviewer `CODEX_HOME` used (same for every round) | log header, runner invocation line |
| builder(s) used (model, from stage, reason) | log |
| pending owner gates (§9 items, Astra gate, acknowledgements) | log |
| next exact action (one imperative sentence with the command or file to touch) | host |

**Resume procedure** (`resume=<checkpoint>` or a new session): read the checkpoint, the review log tail, the newest `result.json` and `git status`/`git log -3` in every repository; verify (a) the task contract file's SHA256 equals the checkpoint's (mismatch → `BLOCKED — OWNER DECISION REQUIRED`, the contract changed) and (b) HEAD and base match the checkpoint. On a HEAD mismatch: list the extra commits, map each to a plan step by its message (`feat(<task>): step n/N — …`, §7.1), mark **every** validation row stale, and record the mapping in the log; never reconstruct from memory. Reconcile the counters (plan / inspection / fix-set / agent): take the checkpoint's values, count the completed runner `result.json` files per mode in the task artefact directory and the round and launch entries in the append-only log, and adopt the highest value for each counter; any operation found in the artefacts or the log but missing from the checkpoint is appended to the log before continuing. Run runner `check` on the approved plan before the first new commit (when an external plan approval exists). Re-run the stale validation rows. Continue at "next exact action". A builder change does not reopen approved plans, completed reviews or accepted dispositions; it re-validates uncommitted work only (§8.5).

---

## Annex A — Intake Record template (output of S0–S3; also the `dry-run` deliverable)

```
INTAKE RECORD — <TASK-ID> — <date>
Task contract: <path> (+ SHA256)      References read: <list>
Dependencies: <task → merge commit, verified ancestor of the origin/<default> tip after fetch>
Preflight: <table: item · expected · observed · OK/FAIL>
  incl. origin/<default> SHA · local default-branch state (stale? reported) · both repos B9 state
  · toolchain · reviewer/builder models listed (first use? availability?) · persona check · hook check · runner reachable
  · Reviewer isolation preflight: <PASS/FAIL · script output path> · reviewer CODEX_HOME <path>
Deterministic risk level: <LEVEL> (deciding triggers: …)   Flags: <S/G/D/X or none>
Jev shadow: <unavailable | recommended level/agents/sol_sufficient/astra_required/checkpoint/confidence · agreement>
Required agents (≤ budget): <agent · assignment · stage>          Agent budget: <n> (used-plan: …)
Agents explicitly NOT required: <agent · why not>
Method skills applied: <skill → stage>
Builder: <model> · fallback: <model, trigger, checkpoint rule>
Reviewer routing: plan review <required? model> · code inspection <model> · final <model> · first-use? · unavailability behaviour (§8.5)
Caps: plan 3 · inspections 3 · fix sets 2 (counters start at 0)
Expected branch: <name>   Base: origin/<default> @ <sha>
Validation strategy: baseline (Annex L §L4 incl. B17) + task-specific: <list, incl. S-flag negative probes>
Files-allowed interpretations stated for the reviewer: <none | list>
Deferred items (Annex L §L7 register): <none | list>
Owner decisions needed: <none | the single question>
Blockers: <none | list>
Confirmation: no product code changed during intake (git status of every repository)
```

## Annex B — Plan template (outside the product repository; never edited after approval)

0. Authority, limits and owner decisions (table: decision → where the plan honours it; explicit prohibitions for this task; the reviewer restriction of §6.14 verbatim: "Do not use web or network tools; this is a private-code review; cite only repository content")
1. Sources and evidence (`file:line` for every "existing" claim; unknowns marked as unverified)
2. Goal and acceptance criteria mapped to proof commands
3. Boundary matrix — what this task does / does not do (per neighbouring task); Files-allowed interpretations
4. Approach and key decisions (with the trade-offs rejected; the simplest thing that works)
5. Version pins (exact) + advisory check evidence + dependency discipline (flag D)
6. File tree at the end of the task (deliverables only)
7. Key file contents or interfaces (verbatim where a reviewer must judge them); **framework-specific decisions cite the official documentation page for the pinned version (`source-driven-development`) or are marked UNVERIFIED**
8. **Threat model** (`security-and-hardening`): trust boundaries, assets, STRIDE per boundary, abuse cases next to use cases — mandatory for HIGH/CRITICAL and for every S-flag sub-surface; the negative probes that prove each sub-surface
9. Implementation steps (binding order; vertical slices sized S/M — an XL step is split; commit boundaries; checkpoints after every 2–3 steps)
10. Validation commands and expected results (baseline + task-specific; evidence format)
11. Security impact and data migration impact
12. Rollback
13. Risks, open points and questions to the reviewer
14. Assumptions ledger

## Annex C — Review log (append-only) and disposition table

Header: start date; host/planner and model; builder(s) and fallback events; reviewer CLI, requested model and effort; inspector; plan path; log path; checkpoint path; Jev shadow record path (or `unavailable`); artefact root; reviewer `CODEX_HOME` (the same for every round); `--repo` used for review and for inspection; scope and authorisation; **caps (plan 3 / fix sets 2 / inspections 3) and the counters**; plan SHA per round.

Per round: counter (`plan round n/3` or `inspection n/3`); `provisional` or `final`; runner mode and arguments (no secrets); artefact directory; CLI version; session id; requested vs observed model; `status`; verdict; summary (verbatim); findings; coverage; limitations; **disposition table**:

| ID | Severity | Class (A/B/C/D) | Root class | Evidence | Prove-It probe (class A: command · red result · green result) | Disposition (fixed in <commit> / handed to <task> / residual (owner, expiry) / refuted / owner-acknowledged <date>) |
|---|---|---|---|---|---|---|

Fix entries: authority (which owner statement or which §2.2 row); root-class check against the two previous fix sets (§4.4); files; probes added; validation re-run; commit; next inspection base/HEAD. Agent runs: roster line, post-run integrity check result (§4.2). Round 0: doubt checklist result and five-axis notes. Every `--feedback` / inspection-note file opens with the §6.14 reviewer restriction; a round whose artefacts show web or network use without contract authorisation is logged as a protocol violation and its web-dependent findings are re-classified on repository evidence only (§6.14).

## Annex D — Completion report and PR body

### D1 — Completion report (§10 order)

```
TASK: …            RISK LEVEL: … (flags …; triggers …)     JEV SHADOW: <unavailable | rec. vs actual · agreement>
AGENTS USED: … (why) · NOT USED: … (why not)     METHOD SKILLS: <skill → stage>
BUILDER: <model> (fallback events: none | opus-5 from Sx, reason)
FILES CHANGED: …
NOTICED BUT NOT TOUCHING: <item → suggested owner/task>
VALIDATIONS: <table id · command · exit · key output>
SECURITY CHECKS: threat model (plan §8) · fail-closed probes · B17 secret scan · five-moves check (§6.7) · least-privilege notes · reviewer-isolation preflight PASS (S1, reviewer CODEX_HOME)
REVIEW ROUNDS: plan n/3 (<model>, artefacts …) · code n/3 (<model>, provisional/final, artefacts …)
FINAL REVIEWER VERDICT: "<verbatim summary>" (final per §8.3 | provisional, Astra gate pending | no inspection required: <reason>)
COMMIT(S): …       PR: #<n> <state> head <sha> (inspected HEAD <sha>)
DEFERRED FINDINGS: <ID → class → root class → owning task / residual (owner, expiry) / owner ack>   (Annex L §L7 updated)
DEFINITION-OF-DONE SELF-CHECK: acceptance criteria met · runtime-verified · tests fail without/pass with · no regressions · scope-clean · lint/format · docs current
PRODUCTION / DEPLOYMENT: none (or the explicit owner authorisation)
CHECKPOINT: <path> (final)
FINAL STATE: <TASK-ID> STATUS: <one of three>
```

### D2 — PR body

Title `<task-id>: <goal>`; sections: scope (task file + approved plan SHA256), change summary (CHANGES MADE / THINGS I DIDN'T TOUCH / POTENTIAL CONCERNS), validation table, review rounds and dispositions (finding IDs, classes, root classes, provisional/final), inspected HEAD and snapshot hash, deferred findings with owning task, security notes, "merge is the owner's action", attribution trailer. No local user paths (`<ws>` placeholder), no secrets.

## Annex E — Checkpoint record and Jev shadow record

### E1 — `<TASK-ID>-CHECKPOINT.md`

```
CHECKPOINT — <TASK-ID> — <ISO timestamp> — written at end of <stage> by <builder model>
Task contract: <path> SHA256 <…>          Standard: DWS-1 <version/draft>
Risk: <LEVEL> flags <…> triggers <…>       Jev shadow: <path | unavailable>
Repo: <path> branch <name> base <sha> HEAD <sha> status <clean | N uncommitted → diff saved at …>
Files changed vs base: <list or count + path of the list>
Completed stages: S0 <ts> · S1 <ts> · … (counters: plan n/3 · inspections n/3 · fix sets n/2 · agents n/<budget>)
Remaining stages: <next> → …
Validation: <id → exit → evidence path> (stale: <ids>)
Findings: <ID class root-class state> …
Reviews: <round → model requested/observed → provisional/final → verdict → artefact>
Reviewer CODEX_HOME: <path>
Builder(s): <model from stage, reason>
Pending owner gates: <none | list>   Pending Astra gate: <none | HEAD sha>
NEXT EXACT ACTION: <one imperative sentence>
```

### E2 — `<TASK-ID>-JEV-SHADOW.md`

```
JEV SHADOW — <TASK-ID> — <ts> — jev_version <…> | unavailable
Request digest: <fields sent>
Response: level <…> agents <…> sol_sufficient <…> astra_required <…> checkpoint <…> confidence <…> rationale <…>
Deterministic decision: level <…> flags <…> agents <…> reviewer <…> gates <…>
Differences: <field → jev vs deterministic>   Ignored (would lower a floor): <fields>
Outcome (S10): actual level/agents/reviewer/findings by class/owner gates → agreement per field
```

---

## Annex L — Larante binding (project-specific facts; update when they change)

### L1 — Locations of this standard

| Copy | Path | Role |
|---|---|---|
| Canonical | documentation repository `LARANTE WEB SİTESİ - v1` → `docs/process/DEVELOPMENT-WORKFLOW-STANDARD-v1.md` | source of truth, reviewed by Codex like any document |
| Skill copy | `%USERPROFILE%\.claude\skills\dev-workflow-standard\STANDARD-v1.md` (+ `SKILL.md`) | makes the one-command protocol available in every repository on this machine; byte-identical to the canonical copy (SHA256 recorded in the PR that introduces or updates it) |

### L2 — Installed capabilities (inventory 2026-09-22)

| Capability | Installed as | Version / id | Reuse decision |
|---|---|---|---|
| Claude Code host | desktop app, Code tab | CLI 2.1.273, model Fable 5.1 (`claude-fable-5-1`); fallback Opus 5 (`claude-opus-5`) | orchestrator/builder; fallback per §8.5 |
| `claudex-loop` plugin | `%USERPROFILE%\.claude\plugins\cache\claudex-loop\claudex-loop\2.1.0\` | skills `claudex-loop`, `claudex-route`, `codex-review`, `codex-build`; runner `skills\claudex-loop\scripts\runner.py` (modes `roles review build inspect check`; `--model --effort --resume --feedback --base --approval --artifacts --timeout --cli`) | **reuse** the runner for every CLI turn (`review`, `check`, `inspect`, optional `build`). The runner enforces **no** round budget: `MAX_ROUNDS` / `MAX_FIX_ROUNDS` / `MAX_INSPECTION_ROUNDS` are skill tunables that the host enforces; under this standard they are 3 / 2 / 3 (§5.1), overriding the skill defaults 5 / 2 / 2. The interview phase of `claudex-loop` is replaced by S0–S4 because the task contract already fixes requirements |
| Codex CLI | `codex-cli 0.154.0` on PATH (`…\Programs\OpenAI\Codex\bin\codex.exe`); the normal `~/.codex` (Desktop app home: `node_repl` + `cua_repl` MCP servers, browser / computer-use / document plugins, GitHub connector, `notify` hook) is **never used for reviews** | catalogue (`codex debug models`): `gpt-5.6-sol`, `gpt-6-astra`, `gpt-5.6-terra`, `gpt-5.6-luna`, … | Sol = ordinary reviewer (first use pending) and provisional reviewer under §8.5; Astra = HIGH/CRITICAL/flag-G reviewer (proven in P1-T01) |
| **Reviewer Codex home** (owner-approved option C, 2026-09-22) | `C:\Users\Monster\.codex-review`: `config.toml` = model `gpt-6-astra` / `high`, `sandbox_mode = "read-only"`, `approval_policy = "never"`, `[features]` apps, computer_use, browser_use, browser_use_external, browser_use_full_cdp_access, image_generation, hooks, js_repl, multi_agent, skill_mcp_dependency_install, skill_search = false, `[windows] sandbox = "elevated"`, account-level remote connectors (`github`, `sites`, `plugin-management`, `openai-templates`, one unnamed app) disabled with `[plugins."…"] enabled = false`; own `auth.json` from a dedicated ChatGPT login (not a copy); no `[mcp_servers]`, marketplaces, `notify`, hooks or `[projects]` | verified 2026-09-22: `mcp list --json` → `[]`; ephemeral validation exposed built-in tools only (exec/apply_patch/view_image/clock/collaboration) — no MCP, plugin, browser, computer-use or GitHub tool; no UAC prompt | **the only home reviews run in**; supplied per process (`CODEX_HOME=…` on the runner command line), never exported or set globally; preflight §L3a |
| `agent-skills` plugin 0.6.10 (Addy Osmani) | claude.ai-managed plugin (desktop app `rpm` directory; referenced by name, never by path) | personas `agent-skills:security-auditor`, `code-reviewer`, `test-engineer`, `web-performance-auditor`; 25 method skills; commands `/review`, `/test`, `/code-simplify`, `/ship`, `/webperf`, `/spec`, `/plan`, `/build`, `/constraints`; references (`definition-of-done`, `orchestration-patterns`, `security-checklist`, `testing-patterns`, …); hooks `simplify-ignore`, `sdd-cache`, `session-start` | personas by stable name (§1); method skills keep/adapt lists (§1); `/spec`, `/plan`, `/build auto`, `/constraints`, `using-agent-skills` not used as orchestrators; **hooks not wired** (none of its external tools — `jq`, `gitleaks`, `semgrep`, `osv-scanner`, `depcruise`, `stryker`, `lighthouse`, `axe` — are installed; installing any is an owner decision) |
| Claude built-in agents | `Plan`, `Explore`, `general-purpose` | — | architecture agent / factual lookup (§1) |
| `Workflow` tool (Ultracode) | built-in; `workflow-authoring` reference | — | bounded workflows only under §4.3 |
| `/code-review ultra` | built-in, owner-triggered, billed | — | owner's supplementary tool, not a stage |
| Jev | **not installed / not connected** (nothing named Jev exists on the machine as of 2026-09-22) | — | interface and shadow-mode policy only (§8.6); integration = owner approval |
| User skills / agents / workflows | `dev-workflow-standard` skill only; no local persona copies | — | — |

### L3 — Paths

| Item | Path |
|---|---|
| Documentation repository (authoritative requirements, architecture, ADRs, task files) | `C:\Users\Monster\Desktop\LARANTE WEB SİTESİ - v1` — GitHub `larantekahve/larante-web-sitesi-v1` |
| Application repository | `C:\Users\Monster\Desktop\larante-platform` — GitHub `larantekahve/larante-platform` (private); `origin/main` = P1-T01 merge `fbd371ae778f25615b127041ef16f9ef493ac68f` |
| Previous Next.js attempt (read-only port source for P1-T02) | `C:\Users\Monster\Desktop\larante-web` (`apps/web/src/config/env.ts`, `site.config.ts`, `src/instrumentation.ts`, `src/lib/features.ts`, `tests/**`) |
| B2B repository (never modified by platform tasks) | `C:\Users\Monster\Desktop\Larante Web Sitesi\b2b-portal\…` |
| Task directory (plan, log, checkpoint, Jev shadow record, feedback notes, runner artefacts) | `C:\Users\Monster\.claude\plans\larante-<task-id-lowercase>\` — files `<TASK-ID>-PLAN.md`, `<TASK-ID>-REVIEW-LOG.md`, `<TASK-ID>-CHECKPOINT.md`, `<TASK-ID>-JEV-SHADOW.md`, `artifacts\feedback-*.md`, `artifacts\claudex-*\` |
| Evidence scratchpad | the session scratchpad directory (`%LOCALAPPDATA%\Temp\claude\<project>\<session>\scratchpad\<task>-evidence\`) |
| Runner | `python "C:\Users\Monster\.claude\plugins\cache\claudex-loop\claudex-loop\2.1.0\skills\claudex-loop\scripts\runner.py"` |

Runner invocations (Windows paths; `PYTHONIOENCODING=utf-8`; stdout to a file in `artifacts\`). **Every Codex-facing invocation is prefixed, in Git Bash, with `CODEX_HOME='C:\Users\Monster\.codex-review'`** — a per-process variable on that command line only (never `export`, never a user or machine variable), so the runner's Codex subprocess inherits the reviewer home while the Desktop app keeps `~/.codex`:

```
CODEX_HOME='C:\Users\Monster\.codex-review' <runner> roles   --host claude
CODEX_HOME='C:\Users\Monster\.codex-review' <runner> review  --host claude --repo "<docs repo>" --plan "<task dir>\<TASK-ID>-PLAN.md" --model <id> --effort high --artifacts "<task dir>\artifacts" --timeout 1800
CODEX_HOME='C:\Users\Monster\.codex-review' <runner> review  --host claude --repo "<docs repo>" --plan "<plan>" --model <same id> --effort high --resume "<previous result.json>" --feedback "<task dir>\artifacts\feedback-round<n>.md" --artifacts "<task dir>\artifacts" --timeout 1800
CODEX_HOME='C:\Users\Monster\.codex-review' <runner> check   --host claude --repo "<docs repo>" --plan "<plan>" --approval "<approved result.json>"
CODEX_HOME='C:\Users\Monster\.codex-review' <runner> inspect --host claude --builder claude --repo "<app repo>" --plan "<plan>" --base <pre-build commit> --feedback "<task dir>\artifacts\feedback-inspect<n>.md" --model <id> --effort high --artifacts "<task dir>\artifacts" --timeout 2400
```

Sessions used by `--resume` live in the reviewer home, so the same prefix is mandatory on every round of a task; the review-log header and each round entry record it.

### L3a — Reviewer-isolation preflight (S1, blocking)

Script: canonical copy `docs/process/reviewer-preflight.sh` in the documentation repository; working copy `%USERPROFILE%\.claude\skills\dev-workflow-standard\reviewer-preflight.sh` (kept byte-identical, like the standard itself). Git Bash: `bash "<path>" [reviewer-home]`; launches no model; exit 0 = PASS, 1 = FAIL, 2 = cannot run. It checks: codex-cli 0.154.x; `mcp list --json` = `[]`; no local plugin marketplace (`openai-bundled` / `openai-primary-runtime`) in the reviewer home; every account-level remote connector row that `plugin list` shows as `installed, enabled` under `openai-curated-remote` (a state local config cannot change) matched by a `[plugins."<name>"]` block whose `enabled = false` line is present (and neutralised by `features.apps = false`); the eleven feature families above = false; config without `notify`, `[projects]`, `[mcp_servers]`, marketplaces, and every `[plugins."…"]` block carrying `enabled = false`; `sandbox_mode = "read-only"`; `approval_policy = "never"`; `login status` = logged in; `CODEX_HOME` not exported. Output is saved to the task directory and named in the Intake Record. FAIL blocks S5 and S8 for the task (§9.5); the host never substitutes `~/.codex`. `codex debug models` under the reviewer home confirms the Sol/Astra catalogue. Residual (§6.14): the built-in `web__run` tool of the code-mode host remains in the reviewer's tool list because codex-cli 0.154.0 offers no verified feature flag that removes it; it is governed by policy, not by configuration — the host's reviewer notes state the no-web restriction and any use is a protocol violation. No unsupported global configuration hack is attempted.

Rollback of the reviewer home: `CODEX_HOME='C:\Users\Monster\.codex-review' codex logout`; optionally revoke that device session in ChatGPT security settings; delete `C:\Users\Monster\.codex-review`; remove the prefix from this section and §L3a. The normal `~/.codex` is untouched throughout.

`--repo` for plan review and for `check` is the documentation repository (the approval is bound to it); for `inspect` it is the repository whose diff is inspected. `--model`/`--effort` MUST repeat the first round's values on `--resume` (the runner refuses mismatches; a different model starts a new session that continues the same counter, §5.1). A provisional review (§8.5) uses the same commands with `--model gpt-5.6-sol` and is labelled `provisional` in the log. A verdict is trusted only after reading `result.json` (`status: completed`, `exit_code: 0`, `response.verdict`, `snapshot.base` + `snapshot.sha256` + per-file hashes equal to the disk state).

### L4 — Validation baseline (application repository; inherited from P1-T01 V1–V16, generalised)

Run from the repository root in Git Bash with `TURBO_TELEMETRY_DISABLED=1 NEXT_TELEMETRY_DISABLED=1`; project Node 22.23.2 via `devEngines.runtime`; pnpm 12.4.2 via Corepack (`corepack pnpm …`); machine Node 24 untouched.

| ID | Check | Command | Expected |
|---|---|---|---|
| B1 | frozen install | `corepack pnpm install --frozen-lockfile` | exit 0; lockfile up to date; supply-chain policies pass |
| B2 | runtime | `corepack pnpm run runtime:check`; `corepack pnpm exec node -v`; bare `node -v` | 22.23.2 / v22.23.2 / v24.19.0 |
| B3 | build | `corepack pnpm -r build` | all workspaces exit 0 |
| B4 | typecheck | `corepack pnpm -r typecheck` | exit 0 |
| B5 | lint | `corepack pnpm lint` | exit 0, 0 warnings (import-boundary rule included) |
| B6 | root tests (boundary suite, direct) | `corepack pnpm test` (`vitest run`, not through the turbo cache) | all pass |
| B7 | workspace tests | `corepack pnpm -r --if-present test` (security-relevant suites also run directly with `--filter`) | all pass |
| B8 | tree / scope | tracked-file diff vs the task's Files allowed (and its stated interpretations) | only allowed paths changed |
| B9 | documentation repository | in the docs repo: `git rev-parse HEAD` equals the docs commit recorded in the task's Intake Record at S1 (or the task's own docs branch, flag X) and `git status --porcelain` shows no **tracked** modification; unrelated **untracked** work is reported in the evidence, not a failure; the pointer in `larante-platform/docs/README.md` is updated only by a documentation task (P1-T07 once its contract is extended per §L7 H4; until then owner-directed documentation work) and a difference between the pointer and the recorded commit is reported, not a failure | clean at the recorded commit |
| B10–B12 | smokes | platform-api `curl` 200; worker exit 0; web/admin 200 — with a valid environment supplied inline by the shell in the evidence command (never from a file; no `.env` is created) | as P1-T01 (ports 3001/3000/3002) |
| B13 | turbo pipeline | dev shell: `pwsh -NoProfile -Command '. ./scripts/dev-shell.ps1; corepack pnpm run turbo:ci; exit $LASTEXITCODE'` | exit 0; no `%APPDATA%\turborepo` created; negative task propagation exit ≠ 0 |
| B14 | advisories | `corepack pnpm audit --audit-level=moderate`; triage per `security-and-hardening` (reachability, fix availability, review date for deferrals) | no unmitigated reachable findings (gate lives in P1-T04 CI) |
| B15 | integrity | `git diff --name-only` empty after builds; manifest/lockfile hashes unchanged by tooling | no tool-rewritten files |
| B16 | machine drift | PATH (HKCU/HKLM), `where.exe node pnpm corepack turbo`, global config dirs before/after | unchanged |
| B17 | secret scan | `git diff <base>...HEAD -U0 \| grep -nEi '(api[_-]?key\|secret\|token\|password\|passwd\|BEGIN (RSA\|EC\|OPENSSH\|PGP) PRIVATE KEY\|AKIA[0-9A-Z]{16}\|ghp_[A-Za-z0-9]{20,}\|sk-[A-Za-z0-9_-]{20,})'` plus a review of every added/changed `.env*` file for key names only (`^[A-Z][A-Z0-9_]*=$`) | no matches other than key names / placeholders; each match listed and justified in the evidence |
| B18 | five-moves check (§6.7) | until P1-T04 ships the repository floor guard: host review of `git diff <base>...HEAD` for new suppressions, skipped/deleted tests, removed assertions, stubs/empty catches, lowered thresholds; recorded as a row with the matches listed | no bar-lowering move, or each one justified by an authorised plan change |

Task-specific checks (from the plan §10) are added, including one negative probe per S-flag sub-surface. Security-relevant tests are executed directly (never trusted from a cache hit) until P1-T04 closes R17.

### L5 — Owner standing rules (apply to every Larante task)

- pnpm through Corepack only (never Bun; no global pnpm/Node/PATH/registry changes; no `corepack enable` globally); Node 22 project-local; machine Node 24 untouched.
- Documentation repository and B2B repository are not modified by application tasks; documentation tasks (e.g. P1-T07) touch only what their task file allows; `LARANTE_CODEX_HANDOFF.md` and the master plan are edited only by owner-directed documentation work.
- No deployment, no production access, no real secrets, no provider SDKs in Phase 1 (B3/B7 open).
- Phase 1 task contracts require **Codex plan review APPROVED and code inspection APPROVED** for every task (Phase 1 README exit list item 4); this contract minimum overrides the LOW/MEDIUM defaults upward (model per §8.3).
- Money is `INTEGER` kuruş, quantities are integers, `REAL`/float prohibited (ADR-015 §6, ADR-016 K1–K2); `cloudflare:*` imports prohibited in the platform; `packages/domain` imports no framework/DB/provider (ADR-001 §Karar 5).
- On REVISE: no automatic patch outside class A within caps; classify, report, stop. PR Ready for Review only with the required final APPROVED. Merge, force-push, branch deletion, deploy: owner only.
- Reports in the owner's command language; status lines verbatim.
- P1-T02 remains implementation-free until this standard takes effect (header Status); its intake and routing (S0–S3, `dry-run`) are re-run against the current draft and the resulting Intake Record supersedes any earlier one.
- The review-log header caps 3 / 2 / 3 apply from the first task run under this standard (P1-T01's header used the skill defaults 5 / 2 / 2 and is not retrofitted).

### L6 — Task-file field mapping (master plan §21.C-8 → this standard)

| Task-file field | Used in |
|---|---|
| TASK ID, Requirement refs, ADR refs, Bağımlılıklar (dependencies) | S0 intake, S1 preflight (dependency merge commits on `origin/main`) |
| Goal, Scope, Out of scope | S2 classification (triggers), plan §2–§3 |
| Files allowed | plan §6, validation B8, §2.2 authority boundary. **Interpretation rule:** Files allowed is read with the repository's established mechanisms — where the workspace pins dependency versions in the `pnpm-workspace.yaml` catalog (P1-T01 convention, 16/16 manifests use `catalog:`), "dependency lines" include the catalog entry for a dependency the task adds; every such interpretation is stated in the plan §3 and in the Intake Record so the plan reviewer can object |
| Data migration impact, Security impact | S2 triggers and flags; plan §11 |
| Acceptance, Tests | plan §2 and §10; validation task-specific rows; S-flag negative probes |
| Rollback | plan §12 |
| "Codex plan + kod denetimi APPROVED" | §8.2 plan review required; §5.3 final inspection |

### L7 — Handoff register (items this standard defers to named tasks; each is a mandatory acceptance item of the owning task)

| ID | Item | Owning task | Acceptance criterion carried into that task |
|---|---|---|---|
| H1 (= P1-T01 R17) | build/test cache integrity | P1-T04 | security-relevant test execution must not produce a false cache hit when Git index file modes or other security-relevant repository metadata change |
| H2 | repository floor guard / CI enforcement of §6.7 | P1-T04 | a diff-scoped guard (reference: `agent-skills` `constraint-driven-development/references/floor-guard.md`, Node, no new external tools) runs in CI on every PR and blocks the five bar-lowering moves; exit 2 (cannot run) never reads as clean; B18 host review is retired only when this is green |
| H3 | decision on a repository-root `CONSTRAINTS.md` and any external scanners (`gitleaks`, `osv-scanner`, `semgrep`) | P1-T04 (owner decision inside that task) | recorded decision; no tool installed without owner approval |
| H4 | project-level `CLAUDE.md` consolidation (DWS pointer + Annex L rules + repository conventions) and the `larante-platform/docs/README.md` pointer | P1-T07 — **pending an owner extension of the P1-T07 contract** (its Files allowed today names only `LARANTE_WEB_ALTYAPI_MIMARISI_V2.md` and the PHASE0 B10 row and states that `larante-platform` is not touched; until the owner adds `CLAUDE.md` per repository and the README pointer to that contract, H4 is an owner decision and no task delivers it) | one `CLAUDE.md` per repository, reviewed like documentation; no duplication of this standard |
| H5 | Jev routing-accuracy register (shadow-mode outcomes per task) | owner (review after 10–20 tasks) | leaving shadow mode is an owner decision; the "never" list of §8.6 is unchanged |
| H6 | reviewer MCP tool-surface acceptance | **closed 2026-09-22** by the dedicated reviewer home (option C, Annex L §L2/§L3a): reviews never run in `~/.codex`; the S1 preflight replaces the per-review classification | — |
| H7 | reviewer-home lifecycle | owner | rollback per Annex L §L3a (logout under the reviewer home, optional session revocation, delete the directory, remove the routing); re-login is needed if the ChatGPT session expires (preflight then fails closed) |

Carry-in rule: H1–H3 become part of the P1-T04 task file's Acceptance section, and H4 part of the P1-T07 contract, by an owner-directed edit before the owning task starts (the current task files do not contain them: P1-T04's Acceptance lists CI trigger, gates, migration idempotency, security baseline, audit and Codex approval only; P1-T07's Files allowed excludes everything but the ARCH document and the B10 row); until that edit exists the items stay open here, and a P1-T04 or P1-T07 plan that omits them is REVISE at S5.
