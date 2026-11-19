-- Register the dbt key pair with Snowflake.
-- Generate the keys first with: bash utils/snowflake/generate_key.sh
--
-- Run as a role that can alter the user (SECURITYADMIN, or the user's owner).
-- Replace your_username below with your Snowflake login name.

-- The value is the contents of .ssh/snowflake_key.pub with the
-- -----BEGIN PUBLIC KEY----- / -----END PUBLIC KEY----- lines removed and all
-- newlines stripped. Pasting the file verbatim is the most common failure here.
alter user your_username set rsa_public_key='MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6z5dDyUZDHVfr+vj1b4fqakojOM7ZpHnqyaLI+Kyvn06bxiQlSJIA7joRB2UKa0DSoku+EJliwn9lRXc1WxFYXMN1nmJciEWp+RX6C0TfSzRv/edB/H7YzhY9t065v8v8fvZ/H34W/IAubmZ8YX580goyCUHOV/U21JlovrnN9AGkAx4y8RELSn4H+barcKmrtqMNDczIG3KyW9cfv//Nz9Jt5hayIeaGyxu/6rwVHFSuQ8g5Q+zed/JOzWAW8I5yki5torF1I+tYjSS9cTv7uU5+Vy4v2QF8Rtf7TMLofvU9qRllsOiV7jeJH04Qzomzy5gRt3nkvc4fcCGZCizpQIDAQAB';

-- Verify. RSA_PUBLIC_KEY_FP in the output must equal the fingerprint printed by
-- generate_key.sh. For the key currently in .ssh/ that is:
--   SHA256:KGL1IGnkx442wPNMjYQBERMsDLaVy+F0am1uMZ9rkS8=
desc user your_username;

-- To rotate: generate a new pair, set rsa_public_key_2 to the new key, switch dbt
-- over, then unset the old one.
--   alter user your_username set rsa_public_key_2='<new key body>';
--   alter user your_username unset rsa_public_key;

-- To remove key-pair auth entirely:
--   alter user your_username unset rsa_public_key;
