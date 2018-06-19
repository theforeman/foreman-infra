Foreman Infrastructure
=============

### Summary
This repo contains puppet modules that are used to manage infrastructure used by the Foreman project. These modules manage many different pieces of software, including Jenkins build slaves, package build machines, the Jenkins frontend, as well as an internal Foreman instance and puppetmaster.

### Updates
For more information what's currently being worked on, see the [Infrastructure Updates](https://projects.theforeman.org/projects/foreman/wiki/Infrastructure_Updates) page in the Foreman wiki.

### Jenkins Job Naming conventions

We're starting to implement some some job naming conventions.

**Note** Because `centos.org` is a shared environment all jobs are prefixed by `foreman-` to denote they're ours.

| **Name**                | **Convention**                        | **Example 1**            | **Example 2**                     |
|-------------------------|---------------------------------------|--------------------------|-----------------------------------|
| Nightly Package Builder | {git-repo}-{git-branch}-release       | foreman-develop-release  | hammer-cli-katello-master-release |
| CI pipeline             | {repository}-{environment}-pipeline   | foreman-nightly-pipeline | plugins-nightly-pipeline          |
| Pull Request testing    | {git-repo}-{optional-concern}-pr-test | katello-pr-test          | foreman-packaging-rpm-pr-test     |
