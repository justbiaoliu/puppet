test_name "puppet module install (with necessary dependency upgrade)"
require 'puppet/acceptance/module_utils'
extend Puppet::Acceptance::ModuleUtils

module_author = "pmtacceptance"
module_name   = "java"
module_dependencies = []

orig_installed_modules = get_installed_modules_for_hosts hosts

teardown do
  installed_modules = get_installed_modules_for_hosts hosts
  rm_installed_modules_from_hosts orig_installed_modules, installed_modules
end

step 'Setup'

stub_forge_on(master)

step "Install an older module version"
on master, puppet("module install #{module_author}-#{module_name} --version 1.6.0") do
  assert_output <<-OUTPUT
    \e[mNotice: Preparing to install into #{master['distmoduledir']} ...\e[0m
    \e[mNotice: Downloading from https://forge.puppetlabs.com ...\e[0m
    \e[mNotice: Installing -- do not interrupt ...\e[0m
    #{master['distmoduledir']}
    └─┬ #{module_author}-#{module_name} (\e[0;36mv1.6.0\e[0m)
      └── #{module_author}-stdlib (\e[0;36mv1.0.0\e[0m)
  OUTPUT
end

on master, puppet("module list --tree --modulepath #{master['distmoduledir']}") do
  assert_output <<-OUTPUT
    #{master['distmoduledir']}
    └─┬ #{module_author}-#{module_name} (\e[0;36mv1.6.0\e[0m)
      └── #{module_author}-stdlib (\e[0;36mv1.0.0\e[0m)
  OUTPUT
end


step "Install a module that requires the older module dependency be upgraded"
on master, puppet("module install #{module_author}-apollo") do
  assert_output <<-OUTPUT
    \e[mNotice: Preparing to install into #{master['distmoduledir']} ...\e[0m
    \e[mNotice: Downloading from https://forge.puppetlabs.com ...\e[0m
    \e[mNotice: Installing -- do not interrupt ...\e[0m
    #{master['distmoduledir']}
    └─┬ #{module_author}-apollo (\e[0;36mv0.0.1\e[0m)
      └── #{module_author}-#{module_name} (\e[0;36mv1.6.0 -> v1.7.1\e[0m)
  OUTPUT
end

on master, puppet("module list --modulepath #{master['distmoduledir']}") do
  assert_output <<-OUTPUT
    #{master['distmoduledir']}
    ├── #{module_author}-apollo (\e[0;36mv0.0.1\e[0m)
    ├── #{module_author}-#{module_name} (\e[0;36mv1.7.1\e[0m)
    └── #{module_author}-stdlib (\e[0;36mv1.0.0\e[0m)
  OUTPUT
end
