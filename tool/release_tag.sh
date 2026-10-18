#!/usr/bin/env bash
# Release helper for pub.dev automation.
#
# check-tag  Fail unless GITHUB_REF_NAME is v<pubspec version> and the changelog
#            has a section for that version.
# create     When the pubspec version is not on pub.dev yet, create a GitHub
#            release for v<version>. Tag pushes made with GH_TOKEN start the
#            publish workflow. The default GITHUB_TOKEN does not.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

command="${1:-create}"

read_version() {
  awk '/^version:/{print $2; exit}' pubspec.yaml
}

read_package_name() {
  awk '/^name:/{print $2; exit}' pubspec.yaml
}

changelog_has_version() {
  local version="$1"
  local escaped
  escaped="$(printf '%s' "$version" | sed 's/[.[\*^$()+?{|]/\\&/g')"
  grep -Eq "^## ${escaped}([[:space:]]|$)" CHANGELOG.md
}

pubdev_status() {
  local package="$1"
  local version="$2"
  local encoded
  encoded="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$version")"
  curl -sS --retry 3 --retry-delay 2 -o /dev/null -w '%{http_code}' \
    "https://pub.dev/api/packages/${package}/versions/${encoded}"
}

changelog_notes() {
  local version="$1"
  awk -v ver="$version" '
    index($0, "## " ver) == 1 && (length($0) == length("## " ver) || substr($0, length("## " ver) + 1, 1) ~ /[[:space:]]/) {
      capture = 1
      next
    }
    capture && /^## / { exit }
    capture { print }
  ' CHANGELOG.md
}

version="$(read_version)"
package="$(read_package_name)"
tag="v${version}"
repo="${GITHUB_REPOSITORY:-hengmengsroin/flutter_cpcl_utils}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.+-][0-9A-Za-z.-]+)?$ ]]; then
  echo "::error::Unsupported pubspec version '${version}'."
  exit 1
fi

case "$command" in
  check-tag)
    if [[ "${GITHUB_REF_NAME:-}" != "$tag" ]]; then
      echo "::error::Tag '${GITHUB_REF_NAME:-}' must be ${tag} to match pubspec.yaml."
      exit 1
    fi
    if ! changelog_has_version "$version"; then
      echo "::error::CHANGELOG.md is missing a '## ${version}' section."
      exit 1
    fi
    echo "Tag ${tag} matches ${package} ${version}."
    ;;
  create)
    echo "Checking ${package} ${version}."
    status="$(pubdev_status "$package" "$version")"
    if [[ "$status" == "200" ]]; then
      echo "Version ${version} is already on pub.dev."
      exit 0
    fi
    if [[ "$status" != "404" ]]; then
      echo "::error::Unexpected pub.dev status ${status} for ${package} ${version}."
      exit 1
    fi
    if ! changelog_has_version "$version"; then
      echo "::error::CHANGELOG.md is missing a '## ${version}' section for unpublished version ${version}."
      exit 1
    fi
    if git ls-remote --exit-code --tags "https://github.com/${repo}.git" "refs/tags/${tag}" >/dev/null 2>&1; then
      echo "::warning::Tag ${tag} already exists, but ${version} is not on pub.dev. Re-run the Publish workflow for that tag."
      exit 0
    fi
    if [[ -z "${GH_TOKEN:-}" ]]; then
      echo "::notice title=Release token missing::Set the RELEASE_TOKEN secret (Contents: Read and write) so this push can create ${tag}. Or push it manually: git tag ${tag} && git push origin ${tag}"
      if [[ "${GITHUB_EVENT_NAME:-}" == "workflow_dispatch" ]]; then
        exit 1
      fi
      exit 0
    fi
    if [[ "${RELEASE_DRY_RUN:-}" == "1" ]]; then
      echo "Would create GitHub release ${tag}."
      exit 0
    fi

    notes_file="$(mktemp)"
    changelog_notes "$version" >"$notes_file"
    if [[ ! -s "$notes_file" ]]; then
      printf 'Publish %s to pub.dev.\n' "$version" >"$notes_file"
    fi
    gh release create "$tag" \
      --repo "$repo" \
      --target "${GITHUB_SHA:?GITHUB_SHA is required to create a release tag}" \
      --title "$tag" \
      --notes-file "$notes_file"
    rm -f "$notes_file"
    echo "Created ${tag}. The tag push publishes ${version} to pub.dev."
    ;;
  *)
    echo "Usage: $0 [check-tag|create]" >&2
    exit 2
    ;;
esac
