To install rvm:
sudo apt-get update
\curl -L https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm requirements

To install ruby using rvm:
rvm install ruby-2.0.0
rvm use 2.0 --default

Needs to be installed additional libs:
sudo apt-get install mysql-client libmysqlclient-dev
*sudo apt-get install xvfb firefox (only for UI tests)

Do not forget to add your own conf.yml file according to the provided examples in the config folder.

!!!Don't forget put own ssh public key into control panel server for user onapp

Environment variables

CONF_PATH - path to custom config file
VIRT_TYPE - virtualization type
TEMPLATE_MANAGER_ID - manager id of template for virtual server

How to run (example):
VIRT_TYPE=kvm6 TEMPLATE_MANAGER_ID=rhel7.1x64 rspec spec/onapp/...