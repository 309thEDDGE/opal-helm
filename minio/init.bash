# This file ensures that minio has the most recent certificates

# Specifies the paths of the source certs and their destination
HELM_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/chart
OPAL_ARTIFACTS_PATH="$(find ~ -name opal_artifacts)"
CERTIFICATES_PATH="$OPAL_ARTIFACTS_PATH"/opal-ops/kubernetes/overlays/local_dev_prod
ENVIRONMENT_PATH="$OPAL_ARTIFACTS_PATH"/opal-ops/kubernetes/base/extra_resources/.env.secrets

# Copy the tls certs
cp "$CERTIFICATES_PATH"/tls.crt "$HELM_PATH"
cp "$CERTIFICATES_PATH"/tls.key "$HELM_PATH"

# Copy the environment secret (There are two steps here to remove the newline character that gets copied originally
ENVIRONMENT_SECRET="$(sed -n 's/MINIO_IDENTITY_OPENID_CLIENT_SECRET=//p' "$ENVIRONMENT_PATH")"
echo "$ENVIRONMENT_SECRET"|tr -d '\n' > "$HELM_PATH"/openid_client_secret.crt
