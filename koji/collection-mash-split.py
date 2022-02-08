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
import StringIO
from distutils.version import LooseVersion

import koji
import kobo.log
import kobo.shortcuts
import kobo.rpmlib
from kobo.hardlink import Hardlink

import yaml

import kobo.tback
kobo.tback.set_except_hook()


CONFIG = {
    "gitloc": "https://github.com/theforeman/foreman-packaging.git",
    "comps_baseloc": "%(tag)s:comps",
    "comps_path": "/mnt/koji/mash/comps",
    "info_log": "/mnt/koji/mash/logs/%(date)s.log",
    "mash_log": "/mnt/koji/mash/logs/%(date)s-mash.log",
    "koji_url": "http://localhost/kojihub",
    "modulemd_baseloc": "%(tag)s:modulemd",
}


class MashConfig(object):
    def __init__(self, collection, version, name_suffix, comps_suffix, comps_directory, modulemd_suffix=None, modulemd_version=0):
        self.name = "{}-{}-{}".format(collection, version, name_suffix)
        self.comps_name = "comps-{}-{}.xml".format(collection, comps_suffix)
        self.comps_path = "{}-{}/{}".format(collection, version, comps_directory)
        if modulemd_suffix is not None:
            self.modulemd_yaml = "modulemd-{}-{}.yaml".format(collection, modulemd_suffix)
        else:
            self.modulemd_yaml = None
        self.modulemd_version = modulemd_version

    @property
    def compses(self):
        return {self.comps_name: self.comps_path}

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

    def get_from_git(self, gitloc, baseloc, filename, finalloc=None):
        """Download a file from remote git repo.

        @param gitloc: git repository url (for ex.: git://git.fedorahosted.org)
        @type gitloc: str
        @param baseloc: base location (for ex.: HEAD:kobo/client)
        @type baseloc: str
        @param filename: file name
        @type filename: str
        @param finalloc: optional local destination directory
        @type finalloc: str
        @return: file contents
        @rtype: str
        """
        repo_name = os.path.basename(gitloc)
        workdir = "/mnt/tmp/gitrepo/%s" % repo_name
        if not os.path.exists(workdir):
            clone_cmd = "git clone %s %s" % (gitloc, workdir)
            kobo.shortcuts.run(clone_cmd, workdir="/mnt/tmp/gitrepo/", can_fail=True)
        cmd = "git fetch && git show remotes/origin/%s/%s" % (baseloc, filename)
        self.logger.debug("running %s" % cmd)
        status, output = kobo.shortcuts.run(cmd, workdir=workdir, can_fail=True)
        if status != 0:
            err_msg = "Could not download %s/%s/%s." % (gitloc, baseloc, filename)
            self.logger.error(err_msg)
            raise SystemExit(err_msg)
        if finalloc is not None:
            if not os.path.exists(finalloc):
                os.makedirs(finalloc)
            final_fn = os.path.join(os.path.realpath(finalloc), filename)
            with open(final_fn, 'w') as resultfile:
                resultfile.write(output)
        else:
            final_fn = None
        return output, final_fn

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

    def inject_modulemd_yml(self, path, modulemd_yaml, modulemd_version=0):
        """Generate modular metadata and inject it.

        @param path: path to repository
        @type path: str
        @param modulemd_yaml: metadata template
        @type modulemd_yaml: str
        @param modulemd_version: the version that should be used in the metadata
        @type modulemd_version: int
        """
        # The epoch number in the NEVRA string is mandatory per spec
        # https://github.com/fedora-modularity/libmodulemd/blob/main/yaml_specs/modulemd_stream_v2.yaml#L668
        # So we can't just use `%{nevra}` here
        cmd = "rpm --query --package {}/*rpm".format(path)
        cmd += " --queryformat='%{name}-%{epochnum}:%{version}-%{release}.%{arch}\n'"
        self.logger.debug("running %s" % cmd)
        status, output = kobo.shortcuts.run(cmd)
        modules = yaml.safe_load(modulemd_yaml)
        modules['data']['artifacts'] = {'rpms': output.splitlines()}
        modules['data']['version'] = modulemd_version
        modules_yaml = os.path.join(path, 'repodata', 'modules.yaml')
        with open(modules_yaml, 'w') as modules_file:
            yaml.dump(modules, modules_file, default_flow_style=False)
        cmd = "modifyrepo_c --mdtype=modules {} {}/repodata".format(modules_yaml, path)
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
        @param comps: comps file content
        @type comps: str
        @return: package name
        @rtype: set
        """
        yum_comps = yum.comps.Comps()
        yum_comps.add(StringIO.StringIO(comps))
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

    def handle_comps(self, whole_path, tmp_path, split_path, mash_config, arches, compses, git_tag,
                     checksum=None, modulemd_yaml=None, modulemd_version=0):
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
        @param compses: dict of comps file names mapped to output paths
        @type compses: list
        @param git_tag: git tag to fetch the comps from (e.g. HEAD)
        @type git_tag: str
        """
        gitloc = CONFIG["gitloc"]

        comps_baseloc = CONFIG["comps_baseloc"] % dict(tag=git_tag)
        comps_path = CONFIG["comps_path"]

        modulemd_baseloc = CONFIG["modulemd_baseloc"] % dict(tag=git_tag)

        all_from_comps = set()
        for comps, output_path in compses.items():
            comps_content, comps_file = self.get_from_git(gitloc, comps_baseloc, comps, comps_path)
            comps_pkg_names = self.list_comps(comps_content)
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
                self.createrepo(tmp_target, comps_file, checksum=checksum)
                if modulemd_yaml:
                    modulemd, _ = self.get_from_git(gitloc, modulemd_baseloc, modulemd_yaml)
                    self.inject_modulemd_yml(tmp_target, modulemd, modulemd_version)
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
            self.logger.warning("%s not in %s" % (pkg, " nor ".join(compses.keys())))

        self.check_tag_listing(mash_config)


def run_mashes(collection, git_tag, mashes):
    log_file = "/var/log/{}-mash-split.log".format(collection)

    arches = ["x86_64"]
    whole_path = "/mnt/koji/releases/whole"
    tmp_path = "/mnt/koji/releases/tmp"
    split_path = "/mnt/koji/releases/split"

    s = MashSplit(log_file)
    for mash_config in mashes:
        s.run_mash(whole_path, mash_config.name)
        s.handle_comps(whole_path, tmp_path, split_path, mash_config.name, arches,
                       mash_config.compses, git_tag, modulemd_yaml=mash_config.modulemd_yaml,
                       modulemd_version=mash_config.modulemd_version)

def generate_modulemd_version(version):
    if version == 'nightly':
        modulemd_version_prefix = '9999'
    else:
        major, minor = version.split('.')
        modulemd_version_prefix = int(major)*100 + int(minor)

    modulemd_version_string = time.strftime("{}%Y%m%d%H%M%S".format(modulemd_version_prefix), time.gmtime())

    return int(modulemd_version_string)


def main():
    try:
        collection = sys.argv[1]
    except IndexError:
        raise SystemExit("Usage: {} collection [version]".format(sys.argv[0]))

    try:
        version = sys.argv[2]
    except IndexError:
        version = "nightly"

    modulemd_version = generate_modulemd_version(version)

    if collection in ("foreman", "foreman-plugins"):
        if version == "nightly":
            git_tag = "rpm/develop"
        else:
            git_tag = "rpm/{}".format(version)

        CONFIG["comps_path"] = "/mnt/koji/mash/comps/foreman"

        mashes = [MashConfig(collection, version, "rhel7-dist", "rhel7", "RHEL/7")]
        if collection == 'foreman' and version not in ('3.1', '3.0', '2.5'):
            modulemd_suffix = 'el8'
        else:
            modulemd_suffix = None
        mashes.append(MashConfig(collection, version, "el8", "el8", "RHEL/8", modulemd_suffix=modulemd_suffix, modulemd_version=modulemd_version))

    elif collection == "foreman-client":
        dists = {
            "el8": "el8",
            "rhel7": "el7",
            "sles11": "sles11",
            "sles12": "sles12",
        }

        if LooseVersion(version) < LooseVersion("3.0"):
            dists["rhel6"] = "el6"

        if version == "nightly":
            git_tag = "rpm/develop"
        else:
            git_tag = "rpm/{}".format(version)

        mashes = [MashConfig(collection, version, dist, dist, code) for dist, code in dists.items()]
    elif collection == 'katello':
        branch_map = {
            'nightly': 'develop',
            '4.4': '3.2',
            '4.3': '3.1',
            '4.2': '3.0',
            '4.1': '2.5',
        }

        git_tag = "rpm/{}".format(branch_map[version])

        mash_config_candlepin = MashConfig(collection, version, "thirdparty-candlepin-rhel7",
                                           "candlepin-server-rhel7", "candlepin/el7")

        # Nightly has no version tag
        if version == 'nightly':
            mash_config_candlepin.name = "katello-thirdparty-candlepin-rhel7"

        el8_candlepin = MashConfig(collection, version, "candlepin-el8", "candlepin-el8", "candlepin/el8")
        el8_candlepin.name = 'katello-candlepin-{}-el8'.format(version)

        if version not in ('4.3', '4.2', '4.1'):
            modulemd_suffix = 'el8'
        else:
            modulemd_suffix = None

        mashes = [
            MashConfig(collection, version, "rhel7", "server-rhel7", "katello/el7"),
            MashConfig(collection, version, "el8", "el8", "katello/el8", modulemd_suffix=modulemd_suffix, modulemd_version=modulemd_version),
            mash_config_candlepin,
            el8_candlepin,
        ]


    elif collection == 'pulpcore':
        CONFIG["gitloc"] = "https://github.com/theforeman/pulpcore-packaging.git"
        git_tag = "rpm/{}".format(version)

        dists = ['el7', 'el8']

        mashes = [MashConfig(collection, version, dist, dist, dist) for dist in dists]

    else:
        raise SystemExit("Unknown collection {}".format(collection))

    run_mashes(collection, git_tag, mashes)

if __name__ == "__main__":
    main()
