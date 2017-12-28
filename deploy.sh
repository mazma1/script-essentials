#!/bin/bash

# update OS and upgrade packages
update_system() {
  echo -e "\e[32m\n==> System Update Started... \n\e[0m"
  sudo apt-get update
  sudo apt-get -y upgrade
  echo -e "\e[32m\n==> System Update Completed! \n\e[0m"
}


# install nvm and node
install_node() {
  echo -e "\e[32m\n==> Installing Node via NVM... \n\e[0m"
  curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash

  export NVM_DIR="/home/ubuntu/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

  nvm install 6.11.2

  NODE=$( node --version )
  echo -e "\e[32m\n==> Installed Node Version: $NODE\e[0m"
}


# clone repo and install dependencies
setup_repo() {
  echo -e "\e[32m\n==> Repo setup in progress... \n\e[0m"
  APP_DIR=post-it

  if [[ -d $APP_DIR ]]; then
    rm -rf $APP_DIR
  fi

  mkdir -p $APP_DIR

  git clone https://github.com/mazma1/post-it.git $APP_DIR
  cd $APP_DIR
  npm install
  npm install # check to install packages that may have failed on first attempt

  npm install node-sass
  echo -e "\e[32m\n==> Repo Setup Completed! \n\e[0m"
}


# run migrations for remote db
run_migration() {
  echo -e "\e[32m\n==> Database Migration in Progress... \n\e[0m"
  source ../env.sh

  npm run reset_db

  cd ../
  echo -e "\e[32m\n==> Database Migration Completed! \n\e[0m"
}


# Configure nginx to route port 80 traffic to port 3000:
configure_nginx() {
  echo -e "\e[32m\n==> Nginx Configuration in Progress... \n\e[0m"
  sudo apt-get install nginx -y
  sudo mv /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default-backup
  sudo cp ./nginx-config /etc/nginx/sites-available/aws-postit
  sudo ln -s /etc/nginx/sites-available/aws-postit /etc/nginx/sites-enabled/aws-postit
  sudo service nginx restart
  echo -e "\e[32m\n==> Nginx Configuration Completed! \n\e[0m"
}


# build the application for production and start
build_app() {
  echo -e "\e[32m\n==> Building App for Production... \n\e[0m"
  cd $APP_DIR
  npm run production

  npm install -g forever
  NODE_ENV=production forever start app/server/dist/bin/www.js

  cd ../
  echo -e "\e[32m\n==> Application Build Completed! \n\e[0m"
}

deploy() {
  echo -e "\e[33m\n==> Project Deployment Started... \n\e[0m"
  update_system
  install_node
  setup_repo
  run_migration
  configure_nginx
  build_app
  echo -e "\e[33m\n==> Project Deployment Completed! \n\e[0m"
}

deploy