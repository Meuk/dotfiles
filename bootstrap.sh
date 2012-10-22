#!/usr/bin/env bash
# Bootstraps a machine for the dotfiles by installing dependencies.
#
# This script will install the following if not already present:
#
#   * Homebrew (Mac only)
#   * RVM + Ruby 1.9.3
#   * zsh
#   * Git
#
# It will then clone the dotfiles repo into a nice directory.
#
# If started with the "server" argument, no system packages will be installed.

function has_command {
  which $1 >/dev/null 2>/dev/null
  return $?
}

# Detect type
if [[ -z $1 ]]; then
  case $(uname) in
    Linux)
      # Assume Debian/Ubuntu is a server if no X server is running
      if has_command "apt-get" && [[ -n $DISPLAY ]]; then
        type="debian"
      else
        type="server"
      fi
      ;;
    Darwin)
      type="mac"
      ;;
    *)
      echo "Unknown OS!"
      exit 1
  esac
else
  if [[ $1 == "server" ]]; then
    type="server"
  else
    echo "Unknown argument $@"
    exit 1
  fi
fi

function installation_message {
  # \e is not portable between Linux and Mac. Mac bash wants to use \E instead.
  # (Cuz Apple hates you.)
  echo -e "\033[33m===== Installing $1...\033[0m"
}

function debian_install {
  [[ $type == "debian" ]] && sudo apt-get install $@
}

function mac_install {
  [[ $type == "mac" ]] && brew install $@
}

# Install stuff

# Homebrew
function install_homebrew {
  installation_message "Homebrew"
  ruby -e "$(curl -fsSkL raw.github.com/mxcl/homebrew/go)"
}

if [[ $type == "mac" ]]; then
  has_command brew || install_homebrew
fi

# RVM
function install_rvm {
  installation_message "RVM"
  \curl -L https://get.rvm.io | bash -s stable --ruby
  source ~/.rvm/scripts/rvm
  installation_message "Ruby 1.9.3"
  rvm install ruby-1.9.3
  rvm use ruby-1.9.3 --default
}

if [[ $type != "server" ]]; then
  type rvm >/dev/null || install_rvm
fi

# zsh
function install_zsh {
  installation_message "zsh"
  debian_install "zsh-beta"
  mac_install "zsh"
}

has_command zsh || install_zsh

# Git
function install_git {
  installation_message "Git"
  debian_install "git git-doc git-man"
  mac_install "git"
}

has_command git || install_git

# Check out the dotfiles

if [[ $type == "server" ]]; then
  dotfiles_dir=~/dotfiles
else
  dotfiles_dir=~/Projects/dotfiles
  mkdir -p ~/Projects
fi

if [[ ! -e $dotfiles_dir ]]; then
  installation_message "dotfiles"
  set -e
  git clone git@github.com:Mange/dotfiles.git $dotfiles_dir
  echo "Installed to $dotfiles_dir. To continue:"
  echo "zsh -c \"cd $dotfiles_dir && rake install\" && exec zsh"
fi
