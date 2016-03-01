To install rvm:
sudo apt-get update
\curl -L https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm requirements

To install ruby using rvm:
rvm install ruby-2.0.0
rvm use 2.0 --default

Create 'log' folder and 'autotest.log' file inside

Do not forget to add your own conf.yml file according to the provided examples in the config folder.

!!!Don't forget put own ssh public key into control panel server for user onapp

Shell commands 'ping' and 'nc' should be runable at control panel

Environment variables

CONF_PATH - path to custom config file
VIRT_TYPE - virtualization type
TEMPLATE_MANAGER_ID - manager id of template for virtual server

How to run (example):
VIRT_TYPE=kvm6 TEMPLATE_MANAGER_ID=rhel7.1x64 rspec spec/onapp/...