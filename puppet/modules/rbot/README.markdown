# RBot Module

Forked from James Fryman <james@frymanet.com> and reworked to use class
inheritance for passing parameters.

This module manages RBot from within Puppet.

# Quick Start

Install and bootstrap an RBot instance

# Requirements

Puppet Labs Standard Library
- http://github.com/puppetlabs/puppetlabs-stdlib

<pre>
  class { 'rbot':
    nickname => 'juicebox',
    servers  => ['irc.frymanet.com'],
    channels => ['#chat'],
   }
</pre>
