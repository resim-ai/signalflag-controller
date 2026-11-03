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

There are no unit tests. Render a change with `helm template` and read the diff, then install it in a Kind cluster with the controller image:

```sh
KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster --name sfc
kind load image-archive respawn-remote.tar --name sfc   # an image built from rerun
kubectl create namespace respawn-system
helm install sfc charts/signalflag-controller -n respawn-system \
  --set controller.image.repository=<image> --set controller.image.tag=<tag>
```

Then create a `Pool` and check it becomes ready, and that `kubectl auth can-i --as=system:serviceaccount:<pool>:worker` gives the worker only what it needs.

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
- `.github/`: CODEOWNERS.

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
