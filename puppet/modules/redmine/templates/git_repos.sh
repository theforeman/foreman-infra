#!/bin/bash

update_repo() {
  pushd /usr/share/redmine_data >/dev/null
  dir=$1; shift;
  repo=$1; shift;
  [ -e git ] || mkdir git

  if [ -e git/${dir}.git ]; then
    cd git/${dir}.git
  elif [ -e git/${dir} ]; then
    # Convert the old full checkout to a bare clone
    mv git/${dir}/.git git/${dir}.git
    rm -rf git/${dir}
    cd git/${dir}.git
    git config --bool core.bare true
  else
    git clone --quiet --bare ${repo} git/${dir}.git
    cd git/${dir}.git
  fi

  git fetch $*

  popd >/dev/null
}

# Sync repositories for all known git repos
curl http://prprocessor-theforeman.rhcloud.com/redmine_repos | ruby -rjson -e '
JSON.load(STDIN).each do |project_name,repos|
  repos.each do |repo,branches|
    org_name, repo_name = repo.split("/", 2)
    puts "#{repo_name} https://github.com/#{repo} #{branches.nil? ? "" : branches.join(" ")}"
  end
end' | while read repo; do
  update_repo $repo
done

cd /usr/share/redmine

# Create repositories in the Redmine projects for all known git repos
curl http://prprocessor-theforeman.rhcloud.com/redmine_repos | script/rails runner -e production '
JSON.load(STDIN).each do |project_name,repos|
  repos.each do |repo,branches|
    org_name, repo_name = repo.split("/", 2)
    repo_path = File.join("/usr/share/redmine_data", "git", "#{repo_name}.git") + File::SEPARATOR
    project = Project.find_by_identifier(project_name) or raise("cannot find project #{project_name}")
    Repository::Git.create!(:identifier => repo_name, :project => project, :url => repo_path) unless Repository.find_by_url(repo_path)
  end
end'

script/rails runner "Repository.fetch_changesets" -e production
