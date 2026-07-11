#!/usr/bin/env bash
# Loads dummy catalog data. Run ONCE, after run-migrations.sh, against an
# empty database. Re-running will duplicate stock movement rows.
set -euo pipefail

NAMESPACE="vpb-mma"

echo "==> Syncing ConfigMap 'db-seed' from db/seed/*.sql"
kubectl create configmap db-seed \
  --namespace "$NAMESPACE" \
  --from-file=db/seed/ \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Running seed Job"
kubectl delete job db-seed --namespace "$NAMESPACE" --ignore-not-found
kubectl apply -f k8s/jobs/db-seed-job.yaml

kubectl wait --for=condition=complete --timeout=120s job/db-seed --namespace "$NAMESPACE" || {
  echo "Seed job did not complete in time — showing logs:"
  kubectl logs job/db-seed --namespace "$NAMESPACE"
  exit 1
}

kubectl logs job/db-seed --namespace "$NAMESPACE"
echo "==> Seed complete."

