#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim:ts=4:sw=4:et

import os
import glob
import yum.comps
import logging
import shutil
import difflib
import time
import re
import sys

import koji
import kobo.log
import kobo.shortcuts
import kobo.rpmlib
from kobo.hardlink import Hardlink

import kobo.tback
kobo.tback.set_except_hook()


CONFIG = {
    "gitloc": "https://github.com/theforeman/foreman-packaging.git",
    "baseloc": "%(tag)s:comps",
    "comps_path": "/mnt/koji/mash/comps",
    "info_log": "/mnt/koji/mash/logs/%(date)s.log",
    "mash_log": "/mnt/koji/mash/logs/%(date)s-mash.log",
    "koji_url": "http://localhost/kojihub",
}

class MashSplit(object):
    """
    Mash out packages from koji and split into repositories according to comps files.
    """
    def __init__(self, logfile):
        self.logger = logging.getLogger("Splitter")
        self.logger.setLevel(logging.DEBUG)
        kobo.log.add_rotating_file_logger(self.logger, logfile)
        kobo.log.add_stderr_logger(self.logger, log_level=logging.INFO)
        info_log = CONFIG["info_log"] % dict(date=time.strftime("%Y-%m-%d-%H%M"))
        kobo.log.add_file_logger(self.logger, info_log, log_level=logging.INFO)
        self.mash_logger = logging.getLogger("Mash")
        self.mash_logger.setLevel(logging.DEBUG)
        mash_log = CONFIG["mash_log"] % dict(date=time.strftime("%Y-%m-%d-%H%M"))
        kobo.log.add_file_logger(self.mash_logger, mash_log, log_level=logging.DEBUG, format="%(message)s")
        self.koji_session = koji.ClientSession(CONFIG["koji_url"])

    def get_from_git(self, gitloc, baseloc, filename, finalloc):
        """Download a file from remote git repo.

        @param gitloc: git repository url (for ex.: git://git.fedorahosted.org)
        @type gitloc: str
        @param baseloc: base location (for ex.: HEAD:kobo/client)
        @type baseloc: str
        @param filename: file name
        @type filename: str
        @param finalloc: local destination directory
        @type finalloc: str
        @return: output file name
        @rtype: str
        """
        if not os.path.exists(finalloc):
            os.makedirs(finalloc)
        final_fn = os.path.join(os.path.realpath(finalloc), filename)
        cmd = "git pull && git archive remotes/origin/%s %s | tar -C %s -x -f -" % (baseloc, filename, finalloc)
        self.logger.debug("running %s" % cmd)
        status, output = kobo.shortcuts.run(cmd, workdir="/mnt/tmp/gitrepo/foreman-packaging/", can_fail=True)
        if status != 0:
            self.logger.warning("Could not download %s/%s/%s. Using local copy." % (gitloc, baseloc, filename))
        if not os.path.exists(final_fn):
            self.logger.error("File %s does not exist." % final_fn)
        return final_fn

    def run_mash(self, path, config):
        """Run mash with given config.

        @param path: output path
        @type path: str
        @param config: mash config name
        @type config: str
        """
        cmd = "/usr/bin/mash -o %s %s" % (path, config)
        tries = 3
        can_fail = True
        for i in range(tries):
            if i == (tries - 1):
                can_fail = False
            self.logger.debug("running %s" % cmd)
            status, output = kobo.shortcuts.run(cmd, can_fail=can_fail)
            for line in output.splitlines():
                self.logger.debug("mash: %s" % line)
                self.mash_logger.info(line)
            if status == 0:
                break

    def createrepo(self, path, comps=None, checksum=None):
        """Run createrepo.

        @param path: path to repository
        @type path: str
        @param comps: comps file (not mandatory)
        @type comps: str
        """
        cmd = "createrepo --pretty --quiet --database "
        if comps:
            cmd += "--groupfile %s " % comps
        if checksum:
            cmd += "--checksum %s " % checksum
        cmd += path
        self.logger.debug("running %s" % cmd)
        kobo.shortcuts.run(cmd)

    def list_srpms_from_rpms(self, rpms_path):
        """Get a list of SRPMs from RPMs.

        @param rpms_path: path to directory containning *.rpm
        @type rpms_path: str
        @return: set of SRPMs
        @rtype: set
        """
        srpms = set()
        for file_name in glob.glob(os.path.join(rpms_path, "*.rpm")):
            hdr = kobo.rpmlib.get_rpm_header(file_name)
            srpm = kobo.rpmlib.get_header_field(hdr, "sourcerpm")
            srpm_name = kobo.rpmlib.parse_nvra(srpm)["name"]
            srpms.add(srpm_name)
        return srpms

    def list_comps(self, comps):
        """Get list of all package names from comps file
        @param comps: comps file path
        @type comps: str
        @return: package name
        @rtype: set
        """
        yum_comps = yum.comps.Comps()
        comps_file = open(comps, "r")
        yum_comps.add(comps_file)
        comps_file.close()
        pkgs = set()
        for group in yum_comps.groups:
            for pkg in group.packages:
                pkgs.add(pkg)
        return pkgs

    def copyout(self, pkg_list, input_path, output_path):
        """Copy out packages from repository but only those name is in list.
        Creates hardlinks instead of new copies.

        @param pkg_list: list of pakckage names to copy
        @type comps: list
        @param input_path: input path
        @type input_path: str
        @param output_path: output path
        @type output_path: str
        """
        _hardlink = Hardlink(test=False)

        self.logger.debug("copyout input:%s output:%s" % (input_path, output_path))

        copied = set()

        for pkg in pkg_list:
            for file_name in glob.glob(os.path.join(input_path, pkg) + "*.rpm"):
                if not kobo.rpmlib.parse_nvra(os.path.basename(file_name))["name"] == pkg:
                    continue # not the exact package name
                copied.add(pkg)
                _hardlink(file_name, output_path)
        return copied

    def move_dir(self, source, target):
        """Move a directory to new location.

        @param source: source path
        @type source: str
        @param target: target path
        @type target: str
        """
        src_list = sorted([ os.path.basename(pkg) + "\n" for pkg in glob.glob(os.path.join(source, "*.rpm")) ])
        dest_list = sorted([ os.path.basename(pkg) + "\n" for pkg in glob.glob(os.path.join(target, "*.rpm")) ])
        output = ""
        for line in difflib.unified_diff(dest_list, src_list, n=0):
            output += line
        if len(output) > 0:
            self.logger.info("New packages in %s:\n%s" % (target, output))

        shutil.rmtree(target)
        shutil.move(source, target)

    def check_tag_listing(self, tag):
        """Compare build names with tag listing.

        @param tag: koji tag
        @type tag: str
        """
        tag_id = self.koji_session.getTag(tag)["id"]
        builds = set()
        for build in self.koji_session.getLatestBuilds(tag):
            builds.add(build["name"])
        pkgs = set()
        for pkg in self.koji_session.listPackages(tagID=tag_id, inherited=True, with_dups=False):
            pkgs.add(pkg["package_name"])
        for pkg in pkgs - set(builds):
            self.logger.warning("No build for package %s in package listing for tag %s" % (pkg, tag))
        return

    def mash_split(self, whole_path, tmp_path, split_path, mash_config, options=None, arches=None, compses=None, git_tag="HEAD", output_paths=None, checksum=None):
        """Run the mash, get comps from git and split the repo according to comps.

        @param whole_path: path to mash whole repo into
        @type whole_path: str
        @param tmp_path: temp path for work before move to split path
        @type tmp_path: str
        @param split_path: target path for split repos
        @type split_path: str
        @param mash_config: name of configuration for mash
        @type mash_config: str
        @param options: list of options (e.g. client and server)
        @type list:
        @param arches: list of arches (e.g. i386 and x86_64)
        @type arches: list
        @param compses: list of comps file names
        @type compses: list
        @param git_tag: git tag to fetch the comps from (e.g. HEAD)
        @type git_tag: str
        @param output_paths: list of relative paths for split repos
        @type: str
        """
        options = options or []
        arches = arches or []

        self.run_mash(whole_path, mash_config)

        gitloc = CONFIG["gitloc"]
        baseloc = CONFIG["baseloc"] % dict(tag=git_tag)
        comps_path = CONFIG["comps_path"]

        if len(options) != len(compses) or len(compses) != len(output_paths):
            self.logger.error("Not enough arguments: options=[%s], compses=[%s], output_paths=[%s]", (", ".join(options), ", ".join(compses), ", ".join(output_paths)))
            return

        all_from_comps = set()
        for option, comps, output_path in zip(options, compses, output_paths):
            comps = self.get_from_git(gitloc, baseloc, comps, comps_path)
            comps_pkg_names = self.list_comps(comps)
            all_from_comps.update(comps_pkg_names)

            rpm_target = None

            # binary
            copied = set()
            for arch in arches:
                tmp_target = os.path.join(tmp_path, "yum", output_path, arch)
                if not os.path.exists(tmp_target):
                    os.makedirs(tmp_target)
                source = os.path.join(whole_path, mash_config, arch, "os", "Packages")
                copied.update(self.copyout(comps_pkg_names, source, tmp_target))
                self.createrepo(tmp_target, comps, checksum=checksum)
                rpm_target = os.path.join(split_path, "yum", output_path, arch)
                if not os.path.exists(rpm_target):
                    os.makedirs(rpm_target)
                self.move_dir(tmp_target, rpm_target)

            # source
            tmp_target = os.path.join(tmp_path, "source", output_path)
            if not os.path.exists(tmp_target):
                os.makedirs(tmp_target)
            source = os.path.join(whole_path, mash_config, "source", "SRPMS")
            self.copyout(self.list_srpms_from_rpms(rpm_target), source, tmp_target)
            self.createrepo(tmp_target, checksum=checksum)
            srpm_target = os.path.join(split_path, "source", output_path)
            if not os.path.exists(srpm_target):
                os.makedirs(srpm_target)
            self.move_dir(tmp_target, srpm_target)

            # test comps vs packages in output tree
            for pkg in comps_pkg_names - copied:
                self.logger.warning("In comps but not in %s tree: %s" % (output_path, pkg))

        # test packages vs comps
        pkgs = set()
        for arch in arches:
            path = os.path.join(whole_path, mash_config, arch, "os", "Packages")
            for pkg in glob.glob(os.path.join(path, "*.rpm")):
                pkgs.add(kobo.rpmlib.parse_nvra(os.path.basename(pkg))["name"])
        for pkg in pkgs - all_from_comps:
            self.logger.warning("%s not in %s" % (pkg, " nor ".join(compses)))

        self.check_tag_listing(mash_config)

def main():
    try:
        version = sys.argv[1]
    except IndexError:
        version = "nightly"

    s = MashSplit("/var/log/katello-mash-split.log")
    options = ["server"]
    arches = ["x86_64"]
    whole_path = "/mnt/koji/releases/whole"
    tmp_path = "/mnt/koji/releases/tmp"
    split_path = "/mnt/koji/releases/split"

    branch_map = {
        'nightly': 'develop',
        '3.15': '2.0',
        '3.14': '1.24',
        '3.13': '1.23',
        '3.12': '1.22',
    }

    git_tag = "rpm/{}".format(branch_map[version])

    mash_config = "katello-{}-rhel7".format(version)
    mash_config_pulp = "katello-pulpcore-{}-el7".format(version)
    if version == 'nightly':
        mash_config_candlepin = "katello-thirdparty-candlepin-rhel7"
    else:
        mash_config_candlepin = "katello-{}-thirdparty-candlepin-rhel7".format(version)

    output_paths = ["katello-{}/katello/el7".format(version)]
    output_paths_candlepin = ["katello-{}/candlepin/el7".format(version)]
    output_paths_pulp = ["katello-{}/pulpcore/el7".format(version)]

    s.mash_split(whole_path, tmp_path, split_path, mash_config, options=arches, arches=arches, compses=["comps-katello-server-rhel7.xml"], git_tag=git_tag, output_paths=output_paths)
    s.mash_split(whole_path, tmp_path, split_path, mash_config_candlepin, options=options, arches=arches, compses=["comps-katello-candlepin-server-rhel7.xml"], git_tag=git_tag, output_paths=output_paths_candlepin)
    if version not in ['3.12', '3.13', '3.14']:
        s.mash_split(whole_path, tmp_path, split_path, mash_config_pulp, options=options, arches=arches, compses=["comps-katello-pulpcore-el7.xml"], git_tag=git_tag, output_paths=output_paths_pulp)

if __name__ == "__main__":
    main()
