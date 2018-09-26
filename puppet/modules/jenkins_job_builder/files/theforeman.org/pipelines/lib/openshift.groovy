def getOcRoute(args) {
    name = args.name

    def command = [
        "jq -r '.items[] | select(.metadata.name == \"${name}\") | .spec.host'"
        "oc get routes --output json",
        
    ]

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        hostname = sh ( "${command.join(' ')}" )
    }
    hostname
}
