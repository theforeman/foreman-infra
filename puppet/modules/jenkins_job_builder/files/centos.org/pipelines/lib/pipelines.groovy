// action, type, version, os, extra_vars = nil
def pipelineVars(Map args) {
    if (args.action == 'install') {
        boxes = ["pipeline-${args.type}-server-${args.version}-${args.os}", "pipeline-${args.type}-smoker-${args.version}-${args.os}"]
    } else if (args.action == 'upgrade') {
        boxes = ["pipeline-upgrade-${args.type}-${args.version}-${args.os}", "pipeline-upgrade-${args.type}-smoker-${args.version}-${args.os}"]
    } else {
        boxes = []
    }

    extra_vars = [
        'pipeline_version': args.version,
        'pipeline_os': args.os,
        'pipeline_type': args.type
    ]

    if (args.extra_vars != null) {
        extra_vars.update(args.extra_vars)
    }

    vars = [
      'boxes': boxes,
      'pipeline': "${args.action}_pipeline.yml",
      'extraVars': extra_vars
    ]
    return vars
}
