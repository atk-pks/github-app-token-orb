#!/bin/bash

# reference: https://docs.github.com/en/developers/apps/building-github-apps/authenticating-with-github-apps#authenticating-as-a-github-app

set -euo pipefail

b64enc() { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }

app_id="${<< parameters.app_id_env >>}"
app_private_key="${<< parameters.app_private_key_env >>}"
duration_seconds="${<< parameters.duration_seconds >>}"

# issued at time, 60 seconds in the past to allow for clock drift
iat=$(($(date +%s) - 60))
exp="$((iat + duration_seconds))"

# create the JWT
signed_content="$(echo -n '{"alg":"RS256","typ":"JWT"}' | b64enc).$(echo -n "{\"iat\":${iat},\"exp\":${exp},\"iss\":${app_id}}" | b64enc)"
sig=$(echo -n "$signed_content" | openssl dgst -binary -sha256 -sign "$app_private_key" | b64enc)
jwt=$(printf '%s.%s\n' "${signed_content}" "${sig}")


# get the access token
org="${CIRCLE_PROJECT_USERNAME}"
repo="${CIRCLE_PROJECT_REPONAME}"
installation_id=$(curl -s \
	-H "Accept: application/vnd.github+json" \
	-H "Authorization: Bearer ${jwt}" \
	-H "X-GitHub-Api-Version: 2022-11-28" \
	https://api.github.com/repos/"${org}"/"${repo}"/installation | jq -r '.id')

access_token=$(curl -s -X POST \
	-H "Authorization: Bearer $jwt" \
	-H "Accept: application/vnd.github+json" \
	-H "X-GitHub-Api-Version: 2022-11-28" \
	https://api.github.com/app/installations/"${installation_id}"/access_tokens | jq -r '.token')

echo "export GITHUB_TOKEN=${access_token}" >> "$BASH_ENV"
