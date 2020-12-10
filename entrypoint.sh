#!/bin/bash

set -e

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
  exit 1
fi

if [[ -z "$GITHUB_REPOSITORY" ]]; then
  echo "Set the GITHUB_REPOSITORY env variable."
  exit 1
fi

if [[ -z "$GITHUB_EVENT_PATH" ]]; then
  echo "Set the GITHUB_EVENT_PATH env variable."
  exit 1
fi

if [[ -z "$WIP_LABELS" ]]; then
  echo "Set the WIP_LABELS env variable."
  exit 1
fi

(jq -r ".pull_request.url" "$GITHUB_EVENT_PATH") || exit 78

URI="https://api.github.com"
API_HEADER="Accept: application/vnd.github.v3+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

ref=$(jq -r ".pull_request.head.ref" "$GITHUB_EVENT_PATH")
number=$(jq -r ".pull_request.number" "$GITHUB_EVENT_PATH")
action=$(jq -r ".action" "$GITHUB_EVENT_PATH")
state=$(jq -r ".review.state" "$GITHUB_EVENT_PATH")

check_contains_wip_label() {
  RESPONSE=$(
    curl -s \
      -X POST \
      -H "${AUTH_HEADER}" \
      -H "${API_HEADER}" \
      "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${number}"
  )

  labels=$(jq ".labels" <<<"$RESPONSE")

  if echo "${labels}" | grep -iE "$WIP_LABELS"; then
    return 1
  else
    return 0
  fi
}

run_ci_when_approved() {
  # https://developer.github.com/v3/pulls/reviews/#list-reviews-on-a-pull-request
  body=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${number}/reviews?per_page=100")
  echo "${body} body jq"
  reviews=$(echo "$body" | jq -r '.[] | {state: .state} | @base64')

  approvals=0

  echo "${approvals}/${APPROVALS} approvals"
  echo "${reviews} reviews"
  echo "${GITHUB_REF#refs/heads/} branch"
  echo "${ref} ref"

  resultado=$(
    curl \
      -X POST -s\
      -H "${AUTH_HEADER}" \
      -H "${API_HEADER}" \
      "${URI}/repos/${GITHUB_REPOSITORY}/actions/workflows/wip.yml/dispatches" \
      -d '{"ref":"'${ref}'"}'
  )
  echo "resultado: ${resultado}"

  for r in $reviews; do
    review="$(echo "$r" | base64 -d)"
    rState=$(echo "$review" | jq -r '.state')

    if [[ "$rState" == "APPROVED" ]]; then
      approvals=$((approvals + 1))
    fi

    echo "${approvals}/${APPROVALS} approvals"

    if [[ "$approvals" -ge "$APPROVALS" ]]; then
      echo "Labeling pull request"

      echo "executar o check lint se já não estiver executado"

      break
    fi
  done
}

process() {
  # run_ci_when_approved
  check_contains_wip_label
  # if [[ "$action" == "submitted" ]] && [[ "$state" == "approved" ]]; then
  #   run_ci_when_approved
  # else
  #   echo "Ignoring event ${action}/${state}"
  # fi
}

process
