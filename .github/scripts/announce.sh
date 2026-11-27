#!/usr/bin/env bash
# announce.sh <version> <notes-file> <release-url>
# Posts a release to the Announcements category of the organization's discussions,
# which live in the JoDi-SDD/.github repository. Uses GH_TOKEN, which must be able
# to write discussions there (the ANNOUNCE_TOKEN secret). Prints the discussion URL.
set -euo pipefail

version=$1 notes=$2 url=$3
owner=${ANNOUNCE_OWNER:-JoDi-SDD}
repo=${ANNOUNCE_REPO:-.github}
category=${ANNOUNCE_CATEGORY:-announcements}

ids=$(gh api graphql \
  -f owner="$owner" -f name="$repo" -f slug="$category" \
  -f query='query($owner: String!, $name: String!, $slug: String!) {
    repository(owner: $owner, name: $name) { id discussionCategory(slug: $slug) { id } }
  }')
repo_id=$(jq -r '.data.repository.id // empty' <<<"$ids")
category_id=$(jq -r '.data.repository.discussionCategory.id // empty' <<<"$ids")
if [ -z "$repo_id" ] || [ -z "$category_id" ]; then
  echo "announce: no '$category' discussion category in $owner/$repo" >&2
  exit 1
fi

body_file=$(mktemp)
{
  cat "$notes"
  printf '\n\n---\n\nFull release: %s\n\nUpdate with `claude plugin update jsdd@jodi-sdd`.\n' "$url"
} >"$body_file"

gh api graphql \
  -f repo="$repo_id" -f category="$category_id" \
  -f title="JoDi-SDD for Claude Code v$version" \
  -F body=@"$body_file" \
  -f query='mutation($repo: ID!, $category: ID!, $title: String!, $body: String!) {
    createDiscussion(input: {repositoryId: $repo, categoryId: $category, title: $title, body: $body}) {
      discussion { url }
    }
  }' --jq '.data.createDiscussion.discussion.url'
