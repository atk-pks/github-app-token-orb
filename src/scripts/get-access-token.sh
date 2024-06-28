#!/bin/bash

# reference: https://docs.github.com/en/developers/apps/building-github-apps/authenticating-with-github-apps#authenticating-as-a-github-app

b64enc() { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }

app_id=${!APP_ID_ENV:-}
b64_app_private_key=${!B64_APP_PRIVATE_KEY_ENV:-}
installation_id=${!INSTALLATION_ID_ENV:-}
duration_seconds=${DURATION_SECONDS-600}

# issued at time, 60 seconds in the past to allow for clock drift
iat=$(($(date +%s) - 60))
exp="$((iat + duration_seconds))"

# create the JWT
signed_content="$(echo -n '{"alg":"RS256","typ":"JWT"}' | b64enc).$(echo -n "{\"iat\":${iat},\"exp\":${exp},\"iss\":${app_id}}" | b64enc)"
sig=$(echo -n "$signed_content" | openssl dgst -binary -sha256 -sign <(echo "${b64_app_private_key}" | base64 -d) | b64enc)
jwt=$(printf '%s.%s\n' "${signed_content}" "${sig}")

# get the access token
org="${CIRCLE_PROJECT_USERNAME}"
repo="${CIRCLE_PROJECT_REPONAME}"

echo "Getting access token for ${org}/${repo}..."

res=$(curl -s -X POST \
	-H "Authorization: Bearer $jwt" \
	-H "Accept: application/vnd.github.v3+json" \
	https://api.github.com/app/installations/"${installation_id}"/access_tokens)

access_token=$(echo "${res}" | jq -rM '.token')
if [[ $access_token == "null" ]]; then
  echo "Error: access_token is empty"
  echo "${res}"
  exit 1
fi

echo "export GITHUB_TOKEN=${access_token}" >> "$BASH_ENV"
