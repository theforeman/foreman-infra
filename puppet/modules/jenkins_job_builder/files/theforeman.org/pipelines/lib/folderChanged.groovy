def folderChanged(folders) {
    def changed = false

    sh "git diff origin/master --name-only > files_changed"
    files_changed = readFile('files_changed').split('\n')

    for (int i = 0; i < folders.size(); i++) {
        changed = changed || !files_changed.findAll { it =~ folders[i] }.empty
    }

    return changed
}
