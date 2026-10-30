# Generated files

Each controller release copies these files from `respawn/config/remote/` in ReSim's controller repository. Don't edit them here: a release overwrites them. The templates read them with `.Files`, and set what depends on the install, such as the namespace.

- `crd/`: the `Pool`, `PoolHandler` and `Batch` CRDs.
- `rbac/role.yaml`: the controller's ClusterRole, and its Role in the controller's namespace.
- `rbac/pool_roles.yaml`: `resim-pool-worker` and `resim-pool-customer`, which each Pool binds in its namespace.
- `rbac/worker_cluster_role.yaml`: the rules of `resim-worker-<environment>`. The chart renders one copy for each environment in `environments`.
