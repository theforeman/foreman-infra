// action, type, version, os, extra_vars = nil
def pipelineVars(Map args) {
    if (args.action == 'install') {
        boxes = ["pipe-${args.type}-server-${args.version}-${args.os}", "pipe-${args.type}-proxy-${args.version}-${args.os}", "pipe-${args.type}-smoker-${args.version}-${args.os}"]
    } else if (args.action == 'upgrade') {
        boxes = ["pipe-up-${args.type}-${args.version}-${args.os}", "pipe-up-${args.type}-proxy-${args.version}-${args.os}", "pipe-up-${args.type}-smoker-${args.version}-${args.os}"]
    } else {
        boxes = ["all"]
    }

    extra_vars = [
        'pipeline_version': args.version,
        'pipeline_os': args.os,
        'pipeline_type': args.type
    ]

    if (args.extra_vars != null) {
        extra_vars.putAll(args.extra_vars)
    }

    vars = [
      'boxes': boxes,
      'pipeline': args.action,
      'extraVars': extra_vars
    ]
    return vars
}
