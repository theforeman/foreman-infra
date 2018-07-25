#!/bin/bash -e

CODE_DIR=$1
DATA_DIR=$2
REDMINE_REPOS=https://prprocessor.theforeman.org/redmine_repos

update_repo() {
  pushd $DATA_DIR >/dev/null
  dir=$1; shift;
  repo=$1; shift;
  [ -e git ] || mkdir git

  if [ ! -e git/${dir}.git ]; then
    git clone --quiet --bare ${repo} git/${dir}.git
    cd git/${dir}.git
    # Only follow HEAD
    git branch | grep -v '*' | xargs --no-run-if-empty git branch -D
  else
    cd git/${dir}.git
  fi

  if [ -z $1 ] ; then
    git fetch --quiet $repo HEAD:$(git rev-parse --abbrev-ref HEAD)
  else
    git fetch --quiet $repo $*
  fi

  popd >/dev/null
}

if [[ ! -n $CODE_DIR ]] || [[ ! -n $DATA_DIR ]] ; then
  echo "Usage: $0 CODE_DIR DATA_DIR"
  exit 1
fi

# Sync repositories for all known git repos
curl -s $REDMINE_REPOS | ruby -rjson -e '
JSON.load(STDIN).each do |project_name,repos|
  repos.each do |repo,branches|
    org_name, repo_name = repo.split("/", 2)
    puts "#{repo_name} https://github.com/#{repo} #{branches.nil? ? "" : branches.map { |branch| "#{branch}:#{branch}" }.join(" ")}"
  end
end' | while read repo; do
  update_repo $repo || echo "Failed to update $repo" > /dev/stderr
done

cd $CODE_DIR

# Create repositories in the Redmine projects for all known git repos
curl -s $REDMINE_REPOS | bin/rails runner -e production '
JSON.load(STDIN).each do |project_name,repos|
  repos.each do |repo,branches|
    org_name, repo_name = repo.split("/", 2)
    repo_path = File.join("'$DATA_DIR'", "git", "#{repo_name}.git") + File::SEPARATOR
    project = Project.find_by_identifier(project_name) or raise("cannot find project #{project_name}")
    Repository::Git.create!(:identifier => repo_name, :project => project, :url => repo_path) unless Repository.find_by_url(repo_path)
  end
end'

# Import the changesets
bin/rails runner "Repository.fetch_changesets" -e production
