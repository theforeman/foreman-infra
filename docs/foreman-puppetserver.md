# Foreman and Puppet Server

Foreman and Puppet are used to manage every machine in the Foreman infrastructure. The Foreman instance is accessible only to those with SSH access to puppetmaster.theforeman.org. Add the following snippet to `~/.ssh/config`:

```
Host foreman-pm
  HostName puppetmaster.theforeman.org
  Port 8122
  User <your SSH user>
  LocalForward 9443 localhost:443
  ExitOnForwardFailure yes
```

and then run:

```
ssh foreman-pm
```

and open https://localhost:9443 in your browser.
