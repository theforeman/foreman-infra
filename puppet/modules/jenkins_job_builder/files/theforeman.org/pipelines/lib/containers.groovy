import groovy.json.JsonOutput

def createTimestamp() {
    (new Date()).format("yyyyMMdd-HHmm", TimeZone.getTimeZone('UTC'))
}

def triggerGithubBuilder(project_name, version, version_build) {
    def inputs = JsonOutput.toJson([
        ref: 'master',
        inputs: [
            project_name: project_name,
            version: version,
            push: 'true',
            registry: 'xyz',
            version_build: version_build
        ]
    ])

    println inputs

    httpRequest httpMode: 'POST',
                authentication: 'github_username_token',
                customHeaders: [[name: 'Accept', value: 'application/vnd.github.v3+json']],
                url: 'https://api.github.com/repos/theforeman/grapple/actions/workflows/build_image.yml/dispatches',
                requestBody: inputs
}
