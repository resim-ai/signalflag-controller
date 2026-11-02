<!-- resim-shared:begin writing-conventions (managed by the resim-shared plugin: edit defaults/claude-md/writing-conventions.md in resim-ai/workspace; its sync-shared-defaults workflow rewrites this copy) -->

## Writing conventions

Shared across ReSim repos. Full policies: `resim-orient` → Code Comments, Never Post Comments Unsolicited; `/comment-audit` sweeps a branch.

### Length

Most agent-written text goes unread because it is too long or dense to skim. This applies to every comment, README, doc, plan, PR description and memory note.

- Lead with the point. Keep sentences short and paragraphs to one to three sentences.
- Say each thing once. Link to the code, `--help` or another doc instead of restating it.
- Leave out chronology, everything you checked, caveats for unlikely cases and edge-case trivia.
- Budgets: a comment ≤ 3 lines, a README section ≤ 15 lines, a whole README ≤ 80 lines, a memory note ≤ 10 lines. If you run over, cut or move detail one level down rather than packing it in.
- Before finishing, delete every sentence a reader would not miss.

### Code comments

Keep useful existing comments: run instructions, test purpose, maintenance rules for templates or generated code, external contracts, non-obvious constraints. Remove a comment only when it is stale, misleading, redundant or narrates an edit. New comments state the constraint, not how you found it.

Never reference ephemeral context; it belongs in the PR description:

- Plans or sub-task labels (`see plan U5`, `KTD`), Linear IDs (`WOB-4129`), other PRs in a stack, or follow-up work.
- Measurements, timings and investigation narration.
- Change history: `now uses X`, `no longer Y`, `per the design`, `added for the Y flow`.

Don't restate well-named code (`// returns the user` above `GetUser()`).

### PR descriptions

Write for engineers and product owners who missed the conversation, in about **150–250 words** for a substantive change and less for a simple one. In order, without mandatory headings:

1. What changes and why, in one or two sentences.
2. Two to four key pieces, if there are distinct ones.
3. Why it matters to the customer or engineering workflow.
4. Dependencies, rollout prerequisites and verification, when relevant.

Omit file inventories, walkthroughs, commands, logs, chronology, abandoned approaches and stack bookkeeping. Link another PR only for a real dependency. Ground claims in the final diff. The `pr-describer` agent's example sets the depth and tone.

### Changelog entries

One or two lines for someone deciding whether a version matters to them: what changed, the parent PR, and any behaviour they need to know.

<!-- resim-shared:end writing-conventions -->
