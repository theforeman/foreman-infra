def gemset(name) {

    def base_name = "${JOB_NAME}-${BUILD_ID}"

    if (name) {
        base_name = base_name + '-' + name
    }

    base_name
}

def configureRVM(ruby = '2.0') {
    withRVM(['rvm gemset empty --force'], ruby)
    withRVM(['gem install bundler'], ruby)
}

def cleanupRVM(name = '', ruby = '2.0') {
    withRVM(["rvm gemset delete ${gemset(name)} --force"], ruby)
}

def withRVM(commands, ruby = '2.0', name = '') {

    commands = commands.join("\n")
    echo commands.toString()

    sh """#!/bin/bash -l
        set +e
        rvm use ruby-${ruby}@${gemset(name)} --create
        ${commands}
    """
}
