# Generated files

Each controller release copies these files from `respawn/config/remote/` in ReSim's controller repository. Don't edit them here: a release overwrites them. The templates read them with `.Files`, and set what depends on the install, such as the namespace.

- `crd/`: the `Berth`, `Harbormaster` and `Batch` CRDs.
- `rbac/role.yaml`: the controller's ClusterRole, and its Role in the controller's namespace.
- `rbac/berth_roles.yaml`: `resim-berth-worker` and `resim-berth-customer`, which each Berth binds in its namespace.
- `rbac/worker_cluster_role.yaml`: the rules of `resim-worker-<environment>`. The chart renders one copy for each environment in `environments`.
