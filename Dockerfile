FROM alpine:latest

LABEL "com.github.actions.name"="WIP blocker with labels in PR"
LABEL "com.github.actions.description"="Github action WIP blocker with labels in Pull requests"
LABEL "com.github.actions.icon"="tag"
LABEL "com.github.actions.color"="gray-dark"

LABEL repository="https://github.com/moodsee/github_actions"
LABEL homepage="https://github.com/moodsee/github_actions"

RUN apk add --no-cache bash curl jq git

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]