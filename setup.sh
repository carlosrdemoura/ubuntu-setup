#!/bin/sh
set -e

# color vars
reset="\033[0m"
success="\033[32m"
warning="\033[33m"
main="\033[34m"

# env vars
export DEBIAN_FRONTEND=noninteractive

# Helper functions
get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

exists() {
  command -v "$1" >/dev/null 2>&1
}

step() {
  echo "\n$main> $1$reset..."
}

check() {
  echo "$success> ✅$reset"
}

warning() {
  echo "$warning>⚠️  $1"
}

install_chrome() {
  step "Installing Google Chrome"

  if exists google-chrome; then
    warning "Google Chrome is already installed, skipping install"
  else
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
    sudo apt update && sudo apt install -y google-chrome-stable
  fi

  check
}

install_vscode() {
  step "Installing VS Code"

  if exists code; then
    warning "VS Code is already installed, skipping install"
  else
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EB3E94ADBE1229CF
    sudo add-apt-repository -y "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
    sudo apt update
    sudo apt -y install code
  fi

  check
}

install_docker() {
  step "Installing Docker"

  if exists docker; then
    warning "Docker is already installed, skipping install"
  else
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    sudo usermod -aG docker $USER
    docker --version
  fi

  check
}

install_docker_compose() {
  step "Installing Docker Compose"

  if exists docker-compose; then
    warning "Docker-compose is already installed, skipping install"
  else
    sudo curl -L "https://github.com/docker/compose/releases/download/$(get_latest_release docker/compose)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    docker-compose --version
  fi

  check
}

install_nodejs() {
  step "Installing NodeJS"

  if exists node; then
    warning "NodeJS is already installed, skipping install"
  else
    curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
    sudo apt install -y nodejs
    node --version
  fi

  check
}

setup() {
  echo "\nUbuntu Setup"

  step "Updating system"
  sudo apt update && sudo apt full-upgrade -y
  check

  step "Installing APT packages"
  sudo apt install -y \
    software-properties-common \
    git \
    curl \
    htop \
    build-essential
  check

  install_chrome
  install_vscode
  install_docker
  install_docker_compose
  install_nodejs

  step "Configure date to use Local Time"
  sudo timedatectl set-local-rtc 1 --adjust-system-clock
  check

  step "Configuring Git"
  git config --global user.name "Carlos Roberto de Moura"
  git config --global user.email "carlos.rdm@outlook.com"
  git config --global credential.helper 'cache --timeout=999999999999'
  git config --global tag.sort -version:refname
  check

  echo "\nFinished!"
}

setup
