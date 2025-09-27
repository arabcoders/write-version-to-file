#!/bin/sh
set -eo pipefail

# Mark the workspace as a safe directory for Git
git config --global --add safe.directory /github/workspace

error() {
    echo -e "\x1b[1;31m${1}\e[0m ${2}"
}

log() {
    echo -e "\x1b[1;32m${1}\e[0m ${2}"
}

if [ -f "${1}" ]; then
    filename="${1}"
elif [ -f "${1#/}" ]; then
    filename="${1#/}"
else
    filename="/github/workspace/${1}"

if [ -z "${2}" ]; then
    placeholder="\${VERSION}"
else
    placeholder=${2}
fi

if [ -z "${3}" ]; then
    WITH_DATE='true'
else
    WITH_DATE=${3}
fi

if [ -z "${4}" ]; then
    WITH_BRANCH='false'
else
    WITH_BRANCH=${4}
fi

log "File Name  : ${filename}"
log "Placeholder: ${placeholder}"
log "Date       : ${WITH_DATE}"
log "Branch     : ${WITH_BRANCH}"

if test -f "${filename}"; then
    content=$(cat "${filename}")
else
    error "Version file not found! Looked for:" "${filename}"
    exit 1
fi

git fetch --tags --force
VERSION_TAG=$(git describe --exact-match --tags 2>/dev/null || git rev-parse --short HEAD)

if [ "${WITH_DATE}" = 'true' ]; then
    log "Adding date to version tag"
    VERSION_TAG="$(date -u +'%Y%m%d')-${VERSION_TAG}"
fi

if [ "${WITH_BRANCH}" = 'true' ]; then
    log "Adding branch name to version tag"
    if [ -n "$GITHUB_HEAD_REF" ]; then
        branchName="$GITHUB_HEAD_REF"
    else
        branchName=$(echo "$GITHUB_REF" | sed 's|refs/heads/||')
    fi

    VERSION_TAG="${branchName}-${VERSION_TAG}"
fi

log "Replacing placeholder '${placeholder}' with '${VERSION_TAG}'."

# Use sed to replace the placeholder with the new tag.
updatedContent=$(sed "s|${placeholder}|${VERSION_TAG}|g" "$filename")
echo "${updatedContent}" >"${filename}"
