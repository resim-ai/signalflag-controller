# signalflag-controller

The Helm chart and manifests for running SignalFlag workers in your own Kubernetes cluster.

For each pool you define, the controller creates a namespace with the service accounts and RBAC that SignalFlag workers need. It also runs the service that picks up the pool's work.

This repository holds the chart, a Kustomize base rendered from it, and the install guide. The controller's source isn't here. SignalFlag builds the controller image, and each release copies the generated CRDs and RBAC into this repository.

## Status

In development. There's no release yet, and the API, `respawn.resim.io/v2alpha1`, may change.

## Licence

MIT. See [LICENSE](LICENSE).
