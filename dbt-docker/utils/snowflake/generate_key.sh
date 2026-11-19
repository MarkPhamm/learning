#!/usr/bin/env bash
# Generate the RSA key pair dbt uses to authenticate to Snowflake.
#
# Writes to .ssh/ at the repo root, which is gitignored and mounted at
# /root/.ssh inside the dbt_snowflake container.
#
# Run from the repo root:
#   bash utils/snowflake/generate_key.sh
#
# Then paste the printed public key body into setup_key.sql and run it in Snowflake.

set -euo pipefail

KEY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.ssh"
KEY_NAME="snowflake_key"
PRIVATE_KEY="${KEY_DIR}/${KEY_NAME}.p8"
PUBLIC_KEY="${KEY_DIR}/${KEY_NAME}.pub"

if [ -f "${PRIVATE_KEY}" ]; then
  echo "${PRIVATE_KEY} already exists. Delete it first to regenerate."
  exit 1
fi

mkdir -p "${KEY_DIR}"
chmod 700 "${KEY_DIR}"

# Snowflake requires PKCS#8. -nocrypt produces an unencrypted key; drop that flag
# to be prompted for a passphrase, then set SNOWFLAKE_PRIVATE_KEY_PASSPHRASE in .env
# and add private_key_passphrase to .dbt/profiles.yml.
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out "${PRIVATE_KEY}" -nocrypt
openssl rsa -in "${PRIVATE_KEY}" -pubout -out "${PUBLIC_KEY}"

chmod 600 "${PRIVATE_KEY}"
chmod 644 "${PUBLIC_KEY}"

echo
echo "Public key body for ALTER USER (header, footer and newlines stripped):"
grep -v 'KEY-----' "${PUBLIC_KEY}" | tr -d '\n'
echo
echo
echo "Local fingerprint, compare against RSA_PUBLIC_KEY_FP from DESC USER:"
openssl rsa -pubin -in "${PUBLIC_KEY}" -outform DER \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64 \
  | sed 's/^/SHA256:/'
