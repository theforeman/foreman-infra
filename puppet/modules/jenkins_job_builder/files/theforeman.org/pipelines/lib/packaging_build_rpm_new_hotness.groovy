pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage("Build RPM") {
            when {
                allOf{
                    anyOf {
                        expression { env.pr_git_url != null && env.scratch == 'true' }
                        expression { env.pr_git_url == null }
                    }
                    expression {
                        sh("""
                            if ! tito release -l | grep -q "${releaser}" ; then
                                if [[ ${releaser} == koji-katello* ]] ; then
                                    # Starting 1.17 the katello packaging repo was merged. Before
                                    # that we can safely ignore this.
                                    echo "Releaser ${releaser} is not configured. Skipping"
                                    exit 0
                                else
                                    echo "ERROR: Releaser ${releaser} is not configured"
                                    exit 1
                                fi
                            fi
                        """)
                    }
                }
            } // when

            steps {
                sh("""
                    git clone https://github.com/theforeman/obal
                    export PYTHONPATH=`pwd`/obal

                    git-annex init
                    ./setup_sources.sh ${project}

                    mkdir rel-eng/build
                    args="-o $(pwd)/rel-eng/build/"
                    [ -n "${tag}" ] && args="${args} --tag=${tag}"
                    [ x"${scratch}" != xfalse ] && args="${args} --scratch"
                    [ x"${gitrelease}" != xfalse -a x${releaser} != xkoji-foreman-nightly -a x${releaser} != xkoji-foreman-jenkins ] && args="${args} --test"
                    [ -n "${nightly_jenkins_job}" ] && args="${args} --arg jenkins_job=${nightly_jenkins_job}"
                    [ -n "${nightly_jenkins_job_id}" ] && args="${args} --arg jenkins_job_id=${nightly_jenkins_job_id}"

                    cd ${project}
                    tito release ${args} ${releaser} 2>&1 | tee tito.log

                    if [ ${PIPESTATUS[0]} -ne 0 ]; then
                      echo "tito release failed, exit code ${PIPESTATUS[0]}"
                      exit 1
                    fi

                    grep "Task info:" tito.log | grep -o "[0-9]*" > tasks || true

                    if [ -s tasks ]; then
                      xargs koji watch-task < tasks
                    fi
                """)
            }
        }
    }
}
