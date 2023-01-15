#!/bin/bash

# reference: https://docs.github.com/en/developers/apps/building-github-apps/authenticating-with-github-apps#authenticating-as-a-github-app

set -euo pipefail

b64enc() { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }

app_id="${APP_ID}"
app_private_key="${APP_PRIVATE_KEY}"
session_time="${SESSION_TIME:-300}"

# issued at time, 60 seconds in the past to allow for clock drift
iat=$(($(date +%s) - 60))
exp="$((iat + session_time))"

signed_content="$( echo -n '{"alg":"RS256","typ":"JWT"}' | b64enc).$(echo -n "{\"iat\":${iat},\"exp\":${exp},\"iss\":${app_id}}" | b64enc)"
sig=$(echo -n "$signed_content" | openssl dgst -binary -sha256 -sign <(printf '%s\n' "$app_private_key") | b64enc)
jwt=$(printf '%s.%s\n' "${signed_content}" "${sig}")

echo $jwt

#curl -s \
#    -H "Authorization: Bearer ${jwt}" \
#    -H "Accept: application/vnd.github.machine-man-preview+json" \
#    "https://api.github.com/app"

#curl -i -X GET \
#-H "Authorization: Bearer $jwt" \
#-H "Accept: application/vnd.github+json" \
#https://api.github.com/app/installations

#curl -i -X POST \
#-H "Authorization: Bearer $jwt" \
#-H "Accept: application/vnd.github+json" \
#https://api.github.com/app/installations/32480052/access_tokens

#curl -i \
#-H "Authorization: Bearer ghs_WpLYMc4YiNMm14fKibGDb94DBMKYno08zv7h" \
#-H "Accept: application/vnd.github+json" \
#https://api.github.com/installation/repositories
