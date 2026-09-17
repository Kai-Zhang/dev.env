#!/bin/bash

set -e

# Constants
REPO_ROOT=~/.config/dev.env
TMP_DIR=/tmp/dev.env
PLATFORM="$(uname -m)"

# Arguments
MIRROR=""
PROXY=""
DISABLE_DOCKER=""
DISABLE_NVIM=""
GO_VERSION="${GO_VERSION:-1.27.1}"

function setup_mac() {
  echo ""
}

function setup_ubuntu() {
  mkdir -p ${TMP_DIR}

  SUDO=""
  if [ "$(whoami)" != "root" ]; then
    SUDO="sudo"
  fi

  if [ -n "${MIRROR}" ]; then
    ${SUDO} sed -i "s#http://.*\.com/ubuntu#http://${MIRROR}/ubuntu#g" /etc/apt/sources.list
    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
      ${SUDO} sed -i "s#URIs: http://.*\.com/ubuntu#URIs: http://${MIRROR}/ubuntu#g" /etc/apt/sources.list.d/ubuntu.sources
    fi
  fi
  ${SUDO} apt update
  ${SUDO} apt upgrade
  ${SUDO} apt install -y ack fuse3 git jq libatomic1 libfuse-dev libfuse3-dev make nodejs openjdk-17-jdk unzip vim wget zsh

  git clone git@github.com:Kai-Zhang/dev.env.git ${REPO_ROOT}

  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" </dev/null
  ${SUDO} chsh -s "$(command -v zsh)" "$USER"
  cp ~/.oh-my-zsh/themes/geoffgarside.zsh-theme ~/.oh-my-zsh/custom/themes/geoffgarside-custom.zsh-theme
  sed -i -E \
    -e '/^PROMPT=/{ /%n@%m/! s/%n/%n@%m/ }' \
    -e '/^PROMPT=/{ s/%\(!\.\#\.\$\)/%(?.%(!.#.$).%{$fg[red]%}%(!.#.$)%{$reset_color%})/ }' \
    ~/.oh-my-zsh/custom/themes/geoffgarside-custom.zsh-theme
  if [ -n "${PROXY}" ]; then
    sed -i "s/# proxy_addr=.*$/proxy_addr=${PROXY}/g" ${REPO_ROOT}/linux/zshrc
    sed -i '/# export https_proxy=.*$/ s/^# //' ${REPO_ROOT}/linux/zshrc
    git config -f ${REPO_ROOT}/.git/config user.name local
    git config -f ${REPO_ROOT}/.git/config user.email foo@example.com
    cd ${REPO_ROOT} && git add -A && git commit -m "local changes" && cd -
    export https_proxy=http://${PROXY} http_proxy=http://${PROXY} all_proxy=sock5://${PROXY}
  fi
  rm -f ~/.zshrc
  ln -s ${REPO_ROOT}/linux/zshrc ~/.zshrc
  rm -f ~/.tmux.conf
  ln -s ${REPO_ROOT}/tmux.conf ~/.tmux.conf
  rm -f /etc/vim/vimrc.local
  ${SUDO} ln -s ${REPO_ROOT}/vimrc /etc/vim/vimrc.local

  ${SUDO} tic -x -o /usr/share/terminfo/ ${REPO_ROOT}/ghostty.ti

  case "${PLATFORM}" in
  aarch64)
    TARGET_PLATFORM=arm64
    NVIM_PLATFORM=arm64
    ;;
  x86_64)
    TARGET_PLATFORM=amd64
    NVIM_PLATFORM=x86_64
    ;;
  *)
    TARGET_PLATFORM=${PLATFORM}
    NVIM_PLATFORM=${PLATFORM}
    ;;
  esac
  wget "https://go.dev/dl/go${GO_VERSION}.linux-${TARGET_PLATFORM}.tar.gz" -O ${TMP_DIR}/go.tar.gz
  ${SUDO} tar zxf ${TMP_DIR}/go.tar.gz -C /usr/local

  if [ -z "${DISABLE_NVIM}" ]; then
    curl -fsSL -o ${TMP_DIR}/nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_PLATFORM}.tar.gz"
    ${SUDO} tar zxf ${TMP_DIR}/nvim.tar.gz -C /usr/local
    ${SUDO} mv /usr/local/nvim-linux-${NVIM_PLATFORM} /usr/local/nvim
    mkdir -p ~/.config
    ln -s ${REPO_ROOT}/nvim ~/.config

    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | NVM_DIR="$HOME/.nvm" PROFILE=/dev/null bash
    export NVM_DIR="$HOME/.nvm"
    . "$NVM_DIR/nvm.sh"
    nvm install --lts
  fi

  if [ -z "${DISABLE_DOCKER}" ]; then
    ${SUDO} curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    ${SUDO} chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | ${SUDO} tee /etc/apt/sources.list.d/docker.list >/dev/null
    ${SUDO} apt update
    ${SUDO} apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    ${SUDO} groupadd -f docker
    ${SUDO} usermod -aG docker $USER
  fi

  HELM_BUILDKITE_APT_KEY_ID="DDF78C3E6EBB2D2CC223C95C62BA89D07698DBC6"
  ${SUDO} apt install -y curl gpg apt-transport-https
  curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey > "${TMPDIR:-/tmp}/helm.gpg"
  if [ "$(gpg --show-keys --with-colons "${TMPDIR:-/tmp}/helm.gpg" | awk -F: '$1 == "fpr" {print $10}' | head -n 1)" != "${HELM_BUILDKITE_APT_KEY_ID}" ]; then echo "ERROR: Unexpected Helm APT key ID: potential key compromise"; exit 1; fi
  cat "${TMPDIR:-/tmp}/helm.gpg" | gpg --dearmor | ${SUDO} tee /usr/share/keyrings/helm.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | ${SUDO} tee /etc/apt/sources.list.d/helm-stable-debian.list
  ${SUDO} apt update
  HELM_VERSION="$(apt-cache madison helm | awk '$3 ~ /^3\./ {print $3}' | sort -Vr | head -n 1)"
  if [ -z "${HELM_VERSION}" ]; then echo "ERROR: No Helm 3 package found"; exit 1; fi
  ${SUDO} apt install -y --allow-downgrades "helm=${HELM_VERSION}"

  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | ${SUDO} gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg >/dev/null
  ${SUDO} chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | ${SUDO} tee /etc/apt/sources.list.d/kubernetes.list
  ${SUDO} chmod 644 /etc/apt/sources.list.d/kubernetes.list
  ${SUDO} apt update
  ${SUDO} apt install -y kubectl

  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | ${SUDO} tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  ${SUDO} chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | ${SUDO} tee /etc/apt/sources.list.d/github-cli.list
  ${SUDO} apt update
  ${SUDO} apt install -y gh

  curl -fsS "https://awscli.amazonaws.com/awscli-exe-linux-${PLATFORM}.zip" -o ${TMP_DIR}/awscli.zip
  unzip ${TMP_DIR}/awscli.zip -d ${TMP_DIR}
  ${SUDO} ${TMP_DIR}/aws/install

  rm -rf ${TMP_DIR}
}

function detect_os() {
  case "$(uname -s)" in
  Darwin)
    echo "macos"
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      echo "${ID}"
    else
      echo "linux"
    fi
    ;;
  *)
    echo "unknown"
    ;;
  esac
}

function print_help() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --disable-docker       Disable the docker installation(for pre-bundled or future configuration)"
  echo "  --disable-nvim         Disable the Neovim and NVM installation"
  echo "  --go-version VERSION   (linux) Set the Go version (default: 1.27.1, env: GO_VERSION)"
  echo "  -h/--help              Print the help message"
  echo "  -m/--mirror MIRROR     (linux) Set the package manager mirror"
  echo "  --proxy PROXY          Set the http proxy of command line"
}

while [ $# -gt 0 ]; do
  case "$1" in
  -h | --help)
    print_help
    exit 1
    ;;
  -m | --mirror)
    MIRROR=$2
    shift 2
    ;;
  --proxy)
    PROXY=$2
    shift 2
    ;;
  --go-version)
    GO_VERSION=$2
    shift 2
    ;;
  --disable-docker)
    DISABLE_DOCKER="true"
    shift
    ;;
  --disable-nvim)
    DISABLE_NVIM="true"
    shift
    ;;
  --)
    shift
    break
    ;;
  -* | *)
    shift
    ;;
  esac
done

OS="$(detect_os)"
case "${OS}" in
ubuntu)
  setup_ubuntu
  ;;
macos)
  setup_mac
  ;;
*)
  echo "Unknown platform ${OS}"
  exit 1
  ;;
esac
