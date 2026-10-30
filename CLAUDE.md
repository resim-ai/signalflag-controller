# CLAUDE.md — signalflag-controller

Repo-specific guidance only. Shared ReSim conventions ship in the `resim-shared` plugin from the `resim-ai/workspace` marketplace. `resim-ai` is a sibling checkout, so its CLAUDE.md doesn't load here; never reference it with a relative path.

This repository is public. Customers can read everything in it, including issues, PRs and commit messages.

## What this is

The Helm chart and Kustomize manifests that install the ReSpawn remote controller in a customer's Kubernetes cluster, under its public name, the SignalFlag controller. It holds YAML and docs only. The controller's source, its image and the generated CRDs and RBAC come from `rerun`: `respawn/cmd/remote` and `respawn/config/remote/`.

The controller manages two cluster-scoped kinds at `respawn.resim.io/v2alpha1`: a `Pool` is a customer's namespace for ReSim work, and a `PoolHandler` runs the service that picks up its pools' work.

## Commands

- Lint: `make lint` (`helm lint --strict`)
- Render the Kustomize base: `make kustomize`. Run it after every chart change and commit the result.
- Check the base matches the chart: `make check`
- Build the Kustomize base and overlays: `make build`
- Render the chart: `helm template signalflag-controller charts/signalflag-controller --namespace respawn-system`

`make kustomize` needs Helm 4. Helm 3 renders the same objects with different blank lines, which fails `make check`.

## PRs

GitHub CLI: `git push -u origin <branch>`, then `gh pr create`; stack a large change with `gh stack`. Every change needs a ReScale approval, and PRs merge by squash only. Bump `version` in `Chart.yaml` with every chart change.

## Testing conventions

There are no unit tests. CI (`.github/workflows/ci.yml`) lints the chart with Helm 3 and 4, checks `kustomize/base` matches the chart, and runs `hack/kind-smoke.sh` on Kind clusters at Kubernetes 1.30 and 1.37.

`hack/kind-smoke.sh` installs the chart in the current kubectl context, checks the CRD protection and the controller's permissions, then uninstalls it. With `CHECK_CONTROLLER=true` it also checks a Pool converges and what its ServiceAccounts can do. That needs a controller image, so CI turns it on only once `appVersion` names a released one. To run it locally with an image built from `rerun`:

```sh
KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster --name sfc
kind load image-archive respawn-remote.tar --name sfc
CHECK_CONTROLLER=true hack/kind-smoke.sh \
  --set controller.image.repository=<image> --set controller.image.tag=<tag> --set controller.image.pullPolicy=Never
```

## Gotchas

- **Never edit `charts/signalflag-controller/generated/`.** Each controller release copies it from `rerun`. To change a CRD or a generated role, change the Go source in `rerun` and regenerate there.
- The templates read the generated files with `.Files` and `fromYaml`, and set the namespace, labels and the CRDs' `helm.sh/resource-policy: keep`. They fail if a generated file holds a kind they don't expect.
- The CRDs are templates, not files under `crds/`, so `helm upgrade` updates them. `helm uninstall` keeps them, and the `respawn-protect-crds` ValidatingAdmissionPolicy refuses to delete them: deleting the `Pool` CRD would delete every pool and its namespace.
- Kubernetes can't create a `PoolHandler` in the same install that creates its CRD, so `poolHandler.enabled` is off by default.
- The controller binds `resim-pool-worker`, `resim-pool-customer`, `resim-worker-<environment>`, `resim-poolhandler-discovery` and `resim-poolhandler-workload` by name. Don't rename them.
- The controller can bind only the ClusterRoles this chart ships, and doesn't hold their permissions, so it can't grant more than the chart contains. The pool roles are generated in `rerun`. Only the two PoolHandler roles are written here, in `templates/poolhandler-roles.yaml`.

## Directory map

- `charts/signalflag-controller/`: the chart. `templates/` holds the templates, `generated/` the files copied from `rerun`, and `values.schema.json` validates `values.yaml`.
- `kustomize/base/`: the chart rendered with its default values, in `respawn-system`. Don't edit `signalflag-controller.yaml` by hand.
- `kustomize/overlays/kind/`: points the controller at the local registry that `rerun`'s Kind tests push to.
- `hack/kind-smoke.sh`: the install test CI runs on Kind.
- `.github/`: CODEOWNERS and the CI workflow.

<!-- resim-shared:begin writing-conventions (managed by the resim-shared plugin: edit defaults/claude-md/writing-conventions.md in resim-ai/workspace; its sync-shared-defaults workflow rewrites this copy) -->

## Writing conventions

Shared across ReSim repos. Each artifact has a different reader and a different lifetime, which is why the same context belongs in one of them and not the others. The `resim-shared` plugin carries the full policies (`resim-orient` → Code Comments, Never Post Comments Unsolicited) and `/comment-audit`, the sweep for a branch you iterated on.

### Code comments

Preserve useful existing comments, including multi-line documentation. Run instructions, test purpose, template or generated-code maintenance requirements, external contracts and non-obvious constraints all earn their place. Keep new comments concise, with enough detail to be useful.

Editing a file is not a reason to strip its comments. Remove comments only when they are stale, misleading, redundant, or merely narrate an edit. Correct outdated portions while retaining useful guidance; when uncertain, inspect the context and preserve the comment until there is a concrete reason to remove it.

Comments must describe the code itself. Do **not** reference ephemeral context that belongs in the PR description:

- Plan documents or sub-task labels (`see plan U5`, `Round 2 design`, `KTD`, `per the orchestration plan`).
- Linear ticket IDs (`WOB-4129`, `RSC-1159`), other PRs in a stack, or follow-up work that will land later.
- Measurements, timings and incident narration from the investigation that produced the change.
- Environment variables cited for narration rather than mechanics (`from AGENT_LATEST_KNOWN_VERSION`).
- Change-history narration such as "added for the Y flow" or "handles the case from issue #123". Durable usage instructions and caller constraints are useful documentation.

That context rots in code — PR descriptions are the right place for it. If a comment wouldn't make sense to a reader who has never seen the originating plan or PR, delete it.

Don't restate what well-named code already says. No `// returns the user` above `func GetUser()`.

Never leave a comment explaining the version you just replaced (`now uses X`, `no longer Y`, `per the design`): it narrates the edit, not the code.

### PR descriptions

Write for engineers and product owners who have not followed the conversation. Explain the feature, its purpose, and the decisions needed to review or roll it out. For a substantive change, aim for roughly **150–250 words**; simple changes can be shorter. This is a guide to useful depth, not a quota.

Use this order, without requiring a heading for each part:

1. **What changes and why:** open with one or two sentences naming the concrete capability or behavior and the problem it addresses. A short before/after example can help.
2. **The important pieces:** explain two to four feature-level changes when there are distinct pieces to understand. Short bullets with descriptive labels work well; do not force a list for a simple change.
3. **Why it matters:** connect those changes to the customer workflow or engineering capability they enable. Explain meaningful scope boundaries when they prevent a likely misunderstanding.
4. **Dependencies and verification, when relevant:** explain any actual merge or activation prerequisite, why it exists, and what it unblocks. Briefly state meaningful validation and remaining gaps; distinguish completed checks from planned checks.

Include technical terms only when they explain behavior, permissions, constraints, or a material tradeoff. Omit file/function inventories, implementation walkthroughs, commands and logs, investigation chronology, abandoned approaches, and conversational status updates. Do not include related-work lists or routine stack bookkeeping. Link another PR only when a reviewer needs it to understand an actual dependency; put that explanation after the feature summary, without a mandatory `Stack position` block or track number in the title.

Ground every claim in the final diff and verified evidence. Rewrite the title and body when scope changes. Keep the title about the delivered capability. Before finishing, check that a reader can explain **what this delivers, why we need it, and what must happen before it is usable** without reading the conversation. Use the shared `pr-describer` agent's example as a guide to depth and tone.

### Changelog entries

Changelog entries are for humans. State what changed and link the parent PR, plus the invariant or behaviour needed to make sense of it. Everything else belongs in the PR description. An entry is read later by someone deciding whether a version matters to them, not by someone reviewing the work.

<!-- resim-shared:end writing-conventions -->
