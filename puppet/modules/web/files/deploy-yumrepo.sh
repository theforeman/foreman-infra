#!/bin/bash

set -xe
# This is a forced SSH command - uncomment to test locally
set -f -- $SSH_ORIGINAL_COMMAND

prepcache() {
	if [[ -e $REPO_PATH ]]; then
		if [[ $MERGE == false ]] && [[ $OVERWRITE == false ]] ; then
			echo "Repo overwrite (${OVERWRITE}) and merge (${MERGE}) are disabled, but ${REPO_PATH} already exists"
			exit 1
		fi
		cp -al $REPO_PATH "$REPO_INSTANCE_PATH"
	else
		mkdir -p $REPO_INSTANCE_PATH
	fi
}

do_rsync() {
	opts=(--archive --verbose --hard-links --log-file "$REPO_RSYNC_LOG")
	if [[ $MERGE == true ]] ; then
		opts+=('--exclude=**/repodata/')
	else
		opts+=('--delete')
	fi
	rsync "${opts[@]}" --log-file-format 'CHANGED %f' "${REPO_SOURCE_RPM}/*" "${REPO_INSTANCE_PATH}/"
	rsync "${opts[@]}" --log-file-format 'CHANGED source/%f' "${REPO_SOURCE_SRPM}/" "${REPO_INSTANCE_PATH}/source/"

	set +f
	for d in "${REPO_INSTANCE_PATH}"/*; do
		(
			cd "$d"

			latest=$(ls -t foreman-release-[0-9]*.rpm 2>/dev/null | head -n1)
			if [[ -n "$latest" ]] ; then
				ln -sf "$latest" foreman-release.rpm
			fi

			latest=$(ls -t foreman-client-release-[0-9]*.rpm 2>/dev/null | head -n1)
			if [[ -n "$latest" ]] ; then
				ln -sf "$latest" foreman-client-release.rpm
			fi

			latest=$(ls -t katello-repos-[0-9]*.rpm 2>/dev/null | head -n1)
			if [[ -n "$latest" ]] ; then
				ln -sf "$latest" katello-repos-latest.rpm
			fi

			if [[ $MERGE == true ]] ; then
				createrepo --skip-symlinks --update .
			fi
		)
	done
	set -f
}

replace() {
	if [[ -e $REPO_PATH ]]; then
		mv "${REPO_PATH}" "${REPO_INSTANCE_PATH_PREV}"
	fi

	mv "${REPO_INSTANCE_PATH}" "${REPO_PATH}"

	if [[ $MERGE == true ]] || [[ $OVERWRITE == true ]] ; then
		if [[ -e "${REPO_INSTANCE_PATH_PREV}" ]]; then
			rm -rf "${REPO_INSTANCE_PATH_PREV}"
		fi
	fi
}

purgecdn() {
	awk '/ CHANGED /{print $5}' "${REPO_RSYNC_LOG}" | xargs --no-run-if-empty fastly-purge "https://yum.theforeman.org/${REPO_DEST}"
	set +f
	for d in "${REPO_PATH}"/*; do
		purge_base="https://yum.theforeman.org/${REPO_DEST}/$(basename $d)"
		fastly-purge ${purge_base} foreman-release.rpm foreman-client-release.rpm
	done
	set -f
}

REPO_SOURCE=$1
REPO_DEST=$2
OVERWRITE=${3:-false}
MERGE=${4:-false}

if [[ -z $REPO_SOURCE ]] || [[ -z $REPO_DEST ]] ; then
	echo "Usage: $0 REPO_SOURCE REPO_DEST OVERWRITE MERGE"
	exit 1
fi

REPO_SOURCE_BASE="rsync://koji.katello.org/releases"
REPO_SOURCE_RPM="${REPO_SOURCE_BASE}/yum/${REPO_SOURCE}"
REPO_SOURCE_SRPM="${REPO_SOURCE_BASE}/source/${REPO_SOURCE}"

DEPLOY_TO="/var/www/vhosts/yum/htdocs"
REPO_PATH="${DEPLOY_TO}/${REPO_DEST}"
REPO_INSTANCE_PATH="${DEPLOY_TO}/$(dirname $REPO_DEST)/.$(basename $REPO_DEST)-$(date "+%Y%m%d%H%M%S")"
REPO_INSTANCE_PATH_PREV="${REPO_INSTANCE_PATH}-previous"

REPO_RSYNC_LOG=$(mktemp)

trap "rm -rf $REPO_RSYNC_LOG $REPO_INSTANCE_PATH" EXIT

prepcache
do_rsync
replace
purgecdn
