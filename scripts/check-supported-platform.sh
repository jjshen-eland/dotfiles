#!/usr/bin/env bash

set -uo pipefail

os="${DOTFILES_UNAME:-$(uname)}"
os_release="${DOTFILES_OS_RELEASE:-/etc/os-release}"

if [ "$os" = "Darwin" ]; then
    exit 0
fi

if [ "$os" != "Linux" ]; then
    printf 'Unsupported operating system: %s. Supported: macOS and Ubuntu 24.04+.\n' "$os" >&2
    exit 2
fi

if [ ! -r "$os_release" ]; then
    printf 'Cannot identify Linux distribution. Supported: Ubuntu 24.04+.\n' >&2
    exit 2
fi

ID=
VERSION_ID=
# The test fixture/path is injected deliberately.
# shellcheck disable=SC1090
. "$os_release"

if [ "${ID:-}" != "ubuntu" ]; then
    printf 'Unsupported Linux distribution: %s. Supported: Ubuntu 24.04+.\n' "${PRETTY_NAME:-${ID:-unknown}}" >&2
    exit 2
fi

version_major=${VERSION_ID%%.*}
version_minor=${VERSION_ID#*.}
version_minor=${version_minor%%.*}
case "$version_major:$version_minor" in
    *[!0-9:]*|:*)
        printf 'Cannot parse Ubuntu version %s. Supported: Ubuntu 24.04+.\n' "${VERSION_ID:-unknown}" >&2
        exit 2
        ;;
esac

if [ "$version_major" -lt 24 ] || { [ "$version_major" -eq 24 ] && [ "$version_minor" -lt 4 ]; }; then
    printf 'Unsupported Ubuntu version: %s. Supported: Ubuntu 24.04+.\n' "$VERSION_ID" >&2
    exit 2
fi
