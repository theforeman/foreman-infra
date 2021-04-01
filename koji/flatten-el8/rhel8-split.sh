#!/bin/bash
HOMEDIR=/root/koji-sync/podman/
BINDIR=$HOMEDIR

dnf install -y createrepo_c libmodulemd librepo python36 python3-hawkey python3-librepo python3-gobject-base "dnf-command(reposync)"


pushd $HOMEDIR/repos
dnf reposync --repoid appstream --repoid powertools --repoid baseos --download-metadata
popd

ARCHES="x86_64"
DATE=$(date -Ih | sed 's/+.*//')

DATEDIR=${HOMEDIR}/koji/${DATE}

if [ -d ${DATEDIR} ]; then
    echo "Directory already exists. Please remove or fix"
    exit
else
mkdir -p ${DATEDIR}
fi

for ARCH in ${ARCHES}; do
    # The archdir is where we daily download updates for rhel8
    ARCHDIR=${HOMEDIR}/repos/
    if [ ! -d ${ARCHDIR} ]; then
	echo "Unable to find ${ARCHDIR}"
	exit
    fi

    # We consolidate all of the default repositories and remerge them
    # in a daily tree. This allows us to point koji at a particular
    # day if we have specific build concerns.
    OUTDIR=${DATEDIR}/${ARCH}
    mkdir -p ${OUTDIR}
    if [ ! -d ${OUTDIR} ]; then
	echo "Unable to find ${ARCHDIR}"
	exit
    else
	cd ${OUTDIR}
    fi

    # Begin splitting the various packages into their subtrees
    ${BINDIR}/splitter.py --action hardlink --target RHEL-8-001 ${ARCHDIR}/baseos/ # &> /dev/null
    if [ $? -ne 0 ]; then
	echo "splitter ${ARCH} baseos failed"
	exit
    fi
    ${BINDIR}/splitter.py --action hardlink --target RHEL-8-002 ${ARCHDIR}/appstream/ # &> /dev/null
    if [ $? -ne 0 ]; then
	echo "splitter ${ARCH} appstream failed"
	exit
    fi
    ${BINDIR}/splitter.py --action hardlink --target RHEL-8-003 ${ARCHDIR}/powertools/ # &> /dev/null
    if [ $? -ne 0 ]; then
	echo "splitter ${ARCH} codeready failed"
	exit
    fi

    # Copy the various module trees into RHEL-8-001 where we want them
    # to work.
    echo "Moving data to ${ARCH}/RHEL-8-001"
    cp -anlr RHEL-8-002/* RHEL-8-001
    cp -anlr RHEL-8-003/* RHEL-8-001
    cp -anlr RHEL-8-001 RHEL-8-001-mod
    # Go into the main tree
    pushd RHEL-8-001
    rm -rf ruby\:2.6*
    rm -rf ruby\:2.7*
    rm -rf nodejs\:14*
    # Mergerepo didn't work so lets just createrepo in the top directory.
    createrepo_c .  &> /dev/null
    popd
    pushd RHEL-8-001-mod
    for d in */ ; do
        echo $d
        pushd $d
        createrepo_c . &> /dev/null
        popd
    done

    # Cleanup the trash 
    rm -rf RHEL-8-002 RHEL-8-003
#loop to the next
done

## Set up the builds so they are pointing to the last working version
cd ${HOMEDIR}/koji/
if [[ -e staged ]]; then
    if [[ -h staged ]]; then
	rm -f staged
    else
	echo "Unable to remove staged. it is not a symbolic link"
	exit
    fi
else
    echo "No staged link found"
fi

echo "Linking ${DATE} to staged"
ln -s ${DATE} staged


# for ARCH in ${ARCHES}; do
#     pushd latest/
#     mkdir -p ${ARCH}
#     dnf --disablerepo=\* --enablerepo=RHEL-8-001 --repofrompath=RHEL-8-001,https://infrastructure.fedoraproject.org/repo/rhel/rhel8/koji/staged/${ARCH}/RHEL-8-001/ reposync -a ${ARCH} -a noarch -p ${ARCH} --newest --delete  &> /dev/null
#     if [[ $? -eq 0 ]]; then
# 	cd ${ARCH}/RHEL-8-001
# 	createrepo_c .  &> /dev/null
#     else
# 	echo "Unable to run createrepo on latest/${ARCH}"
#     fi
#     popd
# done

