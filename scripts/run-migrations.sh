#!/usr/bin/env bash
# Applies all pending SQL migrations to the RDS instance created in Chapter 1.
# Run from the repo root: ./scripts/run-migrations.sh
set -euo pipefail

NAMESPACE="vpb-mma"
SECRET_NAME_AWS=arn:aws:secretsmanager:ap-south-1:282538118471:secret:vpb-mma-dev-db-db-credentials-7UnPuE # matches terraform output db_secret_arn's secret name
K8S_SECRET_NAME="db-credentials"

echo "==> Ensuring namespace '$NAMESPACE' exists"
kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

echo "==> Pulling DB credentials from AWS Secrets Manager"
CREDS_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME_AWS" \
  --query SecretString --output text)

DB_HOST=$(echo "$CREDS_JSON" | jq -r .host)
DB_PORT=$(echo "$CREDS_JSON" | jq -r .port)
DB_NAME=$(echo "$CREDS_JSON" | jq -r .dbname)
DB_USER=$(echo "$CREDS_JSON" | jq -r .username)
DB_PASSWORD=$(echo "$CREDS_JSON" | jq -r .password)

echo "==> Syncing Kubernetes secret '$K8S_SECRET_NAME'"
kubectl create secret generic "$K8S_SECRET_NAME" \
  --namespace "$NAMESPACE" \
  --from-literal=DB_HOST="$DB_HOST" \
  --from-literal=DB_PORT="$DB_PORT" \
  --from-literal=DB_NAME="$DB_NAME" \
  --from-literal=DB_USER="$DB_USER" \
  --from-literal=DB_PASSWORD="$DB_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Syncing ConfigMap 'db-migrations' from db/migrations/*.sql"
kubectl create configmap db-migrations \
  --namespace "$NAMESPACE" \
  --from-file=db/migrations/ \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Re-running migration Job"
kubectl delete job db-migrate --namespace "$NAMESPACE" --ignore-not-found
kubectl apply -f k8s/jobs/db-migrate-job.yaml

echo "==> Waiting for migration Job to complete..."
kubectl wait --for=condition=complete --timeout=180s job/db-migrate --namespace "$NAMESPACE" || {
  echo "Job did not complete in time — showing logs:"
  kubectl logs job/db-migrate --namespace "$NAMESPACE"
  exit 1
}

echo "==> Migration logs:"
kubectl logs job/db-migrate --namespace "$NAMESPACE"
echo "==> Done."

