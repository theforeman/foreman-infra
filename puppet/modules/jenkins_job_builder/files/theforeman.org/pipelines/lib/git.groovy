def ghprb_git_checkout() {
    checkout changelog: true, poll: false, scm: [
        $class: 'GitSCM',
        branches: [[name: '${sha1}']],
        doGenerateSubmoduleConfigurations: false,
        extensions: [[$class: 'PreBuildMerge', options: [fastForwardMode: 'FF', mergeRemote: 'origin', mergeStrategy: 'default', mergeTarget: '${ghprbTargetBranch}']]],
        submoduleCfg: [],
        userRemoteConfigs: [
            [refspec: '+refs/pull/${ghprbPullId}/*:refs/remotes/origin/pr/${ghprbPullId}/*', url: 'https://github.com/${ghprbGhRepository}']
        ]
    ]
}
