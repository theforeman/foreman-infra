// Check if a slave has < 5 GB of free space, wipe out workspaces if it does

import hudson.model.*;
import hudson.util.*;
import jenkins.model.*;
import hudson.FilePath.FileCallable;
import hudson.slaves.OfflineCause;
import hudson.node_monitors.*;

for (node in Jenkins.instance.nodes) {
    computer = node.toComputer()
    if (computer.getChannel() == null) continue
    if (computer.isOffline()) continue

    rootPath = node.getRootPath()
    size = DiskSpaceMonitor.DESCRIPTOR.get(computer).size
    roundedSize = size / (1024 * 1024 * 1024) as int

    println("node: " + node.getDisplayName() + ", free space: " + roundedSize + "GB")
    if (roundedSize < 5) {
        computer.setTemporarilyOffline(true, new hudson.slaves.OfflineCause.ByCLI("disk cleanup"))
        for (item in Jenkins.instance.items) {
            jobName = item.getFullDisplayName()

            if (item.isBuilding()) {
                println(".. job " + jobName + " is currently running, skipped")
                continue
            }

            println(".. wiping out workspaces of job " + jobName)

            workspacePath = node.getWorkspaceFor(item)
            if (workspacePath == null) {
                println(".... could not get workspace path")
                continue
            }

            println(".... workspace = " + workspacePath)

            customWorkspace = item.getCustomWorkspace()
            if (customWorkspace != null) {
                workspacePath = node.getRootPath().child(customWorkspace)
                println(".... custom workspace = " + workspacePath)
            }

            pathAsString = workspacePath.getRemote()
            if (workspacePath.exists()) {
                workspacePath.deleteRecursive()
                println(".... deleted from location " + pathAsString)
            } else {
                println(".... nothing to delete at " + pathAsString)
            }
        }

        computer.setTemporarilyOffline(false, null)
    }
}
