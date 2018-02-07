# jenkins_job_builder

`files/theforeman.org` contains job definitions for Jenkins

## development setup

Warning: Your local Jenkins may not work for all the jobs you try to import, because some jobs rely on plugins and global environment variables. Unfortunately, we do not have a list of plugins and variables in a source control yet.


* Set up a local Jenkins instance
  1. In Docker
      * you can use official [Docker images](https://hub.docker.com/r/jenkins/jenkins/)
      * `docker run --name jenkins-lts -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts`
  2. Using Puppet
      * Approved [Puppet module](https://forge.puppet.com/rtyler/jenkins).

* `pip install --user jenkins-job-builder`
* create `jjb.ini` containing credentials and location of your Jenkins:

```
[jenkins]
user=admin
password=changeme
url=http://jenkins.example.com:8080

[job_builder]
ignore_cache=True
keep_descriptions=False
recursive=True
allow_duplicates=False
```

* `cd foreman-infra/puppet/modules/jenkins_job_builder/files/theforeman.org`
* `jenkins-jobs --conf ~/jjb.ini -l debug update -r . release_mash` to update the `release_mash` job. Omit the job name to update all.
