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
sudo apt-get install nodejs

Navigate your project folder and run the following commands:
bundle
rake db:create
rake db:migrate
rake db:seed  - credentials should be generated
rails s

Do not forget to add your own conf.yml and database.yml files according to the provided examples in the config folder.

After installation go to your web browser and open the http://0.0.0.0:3000/ page. To login use credentials generated while running rake db:seed.