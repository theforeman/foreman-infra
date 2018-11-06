def ghprb_git_checkout() {
    checkout changelog: true, poll: false, scm: [
        $class: 'GitSCM',
        branches: [[name: '${sha1}']],
        doGenerateSubmoduleConfigurations: false,
        extensions: [[$class: 'PreBuildMerge', options: [fastForwardMode: 'FF', mergeRemote: 'origin', mergeTarget: '${ghprbTargetBranch}']]],
        submoduleCfg: [],
        userRemoteConfigs: [
            [refspec: '+refs/heads/${ghprbTargetBranch}:refs/remotes/origin/${ghprbTargetBranch} +refs/pull/${ghprbPullId}/*:refs/remotes/origin/pr/${ghprbPullId}/*', url: 'https://github.com/${ghprbGhRepository}']
        ]
    ]
}

def archive_git_hash(ref = 'HEAD') {
    def hash = sh(script: "git rev-parse ${ref} | tee commit", returnStdout: true).trim()
    archiveArtifacts(artifacts: 'commit')
    return hash
}
