#!/usr/bin/env bash
# Installs the chart into the current kubectl context, checks what it installed, then uninstalls it. Extra
# arguments go to helm install, for example to set the controller image.
#
# With CHECK_CONTROLLER=true it also waits for the controller, and checks a Pool converges and its ServiceAccounts
# get only what they need. That needs a controller image the cluster can pull.
#
# Usage: hack/kind-smoke.sh [helm install flags...]
set -euo pipefail

namespace=respawn-system
release=signalflag-controller
chart=charts/signalflag-controller
controller=system:serviceaccount:${namespace}:signalflag-controller

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# expect ANSWER ARGS... checks kubectl auth can-i ARGS answers ANSWER.
expect() {
  local want=$1 got
  shift
  got=$(kubectl auth can-i "$@" 2>/dev/null || true)
  [[ ${got} == "${want}" ]] || fail "kubectl auth can-i $* = ${got:-error}, want ${want}"
  echo "ok: can-i $* = ${want}"
}

# eventually DESCRIPTION COMMAND... retries COMMAND for up to a minute.
eventually() {
  local description=$1
  shift
  for _ in $(seq 60); do
    if "$@" >/dev/null 2>&1; then
      echo "ok: ${description}"
      return
    fi
    sleep 1
  done
  fail "timed out waiting until ${description}"
}

crd_delete_refused() {
  ! kubectl delete crd pools.respawn.resim.io --dry-run=server
}

pool_ready() {
  [[ $(kubectl get pool smoke -o jsonpath='{.status.conditions[?(@.type=="PoolReady")].status}') == True ]]
}

namespace_gone() {
  ! kubectl get namespace smoke
}

kubectl create namespace "${namespace}" --dry-run=client -o yaml | kubectl apply -f -
helm install "${release}" "${chart}" --namespace "${namespace}" "$@"
kubectl wait --for condition=established --timeout=60s \
  crd/pools.respawn.resim.io crd/poolhandlers.respawn.resim.io crd/batches.respawn.resim.io

eventually "the API server refuses to delete the Pool CRD" crd_delete_refused

# The controller binds the shipped roles and nothing else, and reads Secrets only in its own namespace.
expect yes bind clusterrole/resim-pool-worker --as "${controller}"
expect yes bind clusterrole/resim-worker-prod --as "${controller}"
expect no bind clusterrole/cluster-admin --as "${controller}"
expect no create roles --namespace default --as "${controller}"
expect no create pods --namespace default --as "${controller}"
expect yes get secrets --namespace "${namespace}" --as "${controller}"
expect no list secrets --namespace "${namespace}" --as "${controller}"
expect no get secrets --namespace default --as "${controller}"

if [[ ${CHECK_CONTROLLER:-false} == true ]]; then
  kubectl --namespace "${namespace}" rollout status deployment/signalflag-controller --timeout=180s
  kubectl apply -f - <<'POOL'
apiVersion: respawn.resim.io/v2alpha1
kind: Pool
metadata:
  name: smoke
spec:
  orgID: smoke.example.com
  environment: prod
  poolLabel: smoke
  identity:
    workerRoleARN: arn:aws:iam::123456789012:role/smoke-worker
    customerRoleARN: arn:aws:iam::123456789012:role/smoke-customer
POOL
  eventually "the Pool is ready" pool_ready
  worker=system:serviceaccount:smoke:worker
  customer=system:serviceaccount:smoke:customer
  expect yes get nodes --as "${worker}"
  expect yes create jobs.batch --namespace smoke --as "${worker}"
  expect yes list events --namespace smoke --as "${worker}"
  expect no list pods --namespace default --as "${worker}"
  expect no get secrets --namespace smoke --as "${worker}"
  expect no delete persistentvolumes --as "${worker}"
  expect yes list pods --namespace smoke --as "${customer}"
  expect no create pods --namespace smoke --as "${customer}"
  kubectl delete pool smoke
  eventually "the pool's namespace is deleted" namespace_gone
else
  echo "skipped: the controller checks, because CHECK_CONTROLLER isn't true"
fi

helm uninstall "${release}" --namespace "${namespace}" --wait
kubectl get crd pools.respawn.resim.io >/dev/null || fail "helm uninstall deleted the Pool CRD"
if kubectl get clusterrole resim-pool-worker >/dev/null 2>&1; then
  fail "helm uninstall left resim-pool-worker behind"
fi
echo "ok: uninstall kept the CRDs and removed the rest"
