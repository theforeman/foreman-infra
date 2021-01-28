// action, type, version, os, extra_vars = nil
def pipelineVars(Map args) {
    boxes = ["pipe-*"]

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
