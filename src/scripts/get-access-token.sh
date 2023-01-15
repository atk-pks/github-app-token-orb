#!/bin/bash

# reference: https://docs.github.com/en/developers/apps/building-github-apps/authenticating-with-github-apps#authenticating-as-a-github-app

app_id=${!APP_ID_ENV:-}
b64_app_private_key=${!B64_APP_PRIVATE_KEY_ENV:-}
duration_seconds=${DURATION_SECONDS-600}

# issued at time, 60 seconds in the past to allow for clock drift
iat=$(($(date +%s) - 60))
exp="$((iat + duration_seconds))"

# create the JWT
signed_content="$(echo -n '{"alg":"RS256","typ":"JWT"}' | base64).$(echo -n "{\"iat\":${iat},\"exp\":${exp},\"iss\":${app_id}}" | base64)"
sig=$(echo -n "$signed_content" | openssl dgst -binary -sha256 -sign <(echo "${b64_app_private_key}" | base64 -D) | base64)
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
