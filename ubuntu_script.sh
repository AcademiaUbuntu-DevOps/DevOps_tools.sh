#!/bin/bash

# Automatizar la instalacaion de todas las aplicaciónes de Ubuntu solicitadas en el Lab1

#   Docker-ce
#   microk8s ?
#   kubectl
#   kubens
#   kubectx
#   HELM
#   terraform

# Códigos de Colores
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'


are_you_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "Hey! This script has to be run as root, type "sudo su", then back again"
        exit 1
    fi
}

f_OS_SELECTOR() {
    # Package Manager

    if [[ -f /etc/ubuntu-advantage/uaclient.conf ]]; then ##### Ubuntu Based
        echo -e "$grn Linux Ubuntu Based Distro detected $end"
        sleep 3
        OS="Ubuntu"
        PM="apt"
        return

    elif [[ -f /etc/debian_version ]]; then ##### Debian Based
        echo -e "$grn Linux Debian Based Distro detected $end, be carefull"
        sleep 3
        OS="Debian"
        PM="apt"
        return
        

    elif [[ -f /etc/redhat_release ]]; then ##### RedHat Based
        echo -e "$red Error: RedHat Based Distro detected $end"
        OS="Centos"
        PM="dnf"
        exit 1
    fi
}

f_UPGRADE() {
    ##################### UBUNTU "apt"
    echo -e "\n $cyn ######################### Refresh OS repo $end"
    sleep 2
    $PM update

    echo -e "\n $cyn ######################### Installing Updates $end"
    sleep 2
    $PM upgrade -y
    sleep 3

    echo -e "\n $cyn ######################### Installing Base Apps $end"
    sleep 2
    $PM install \
        snap \
        python3 \
        python3-pip \
        unzip \
        wget \
        vim \
        git \
        curl \
        htop \
        apt-transport-https ca-certificates curl \
        gnupg software-properties-common \
        -y # no-interactive mode
}


f_GENERAL() {
    echo -e "$cyn \n######################### General configurations $end"
    sleep 1
    mkdir -p ~/Workspace/Logs ~/Workspace/minikube ~/Workspace/Scripts ~/Workspace/Temp ~/Workspace/Repos

    # vim configurations
    mkdir -p $HOME/.vim/swapfiles $HOME/.vim/swapfiles $HOME/.vim/backupfiles $HOME/.vim/undodir $HOME/.local/bin
    echo -e "Generating symlink to vimrc"
    ln -sf ~/.dotfiles/vimrc ~/.vimrc
}


f_DOCKER(){
    echo -e "$cyn \n#################### Installing Docker $end"
    sleep 2

    which docker   || echo -e "$yel Was already installed $end" && return

    # Removing old version of Docker
    sudo apt install gnome-terminal -y
    sudo apt remove docker-desktop -y
    rm -rf $HOME/.docker/desktop
    sudo rm  -rf /usr/local/bin/com.docker.cli
    sudo apt purge docker-desktop -y

    # Add Docker’s official GPG key:
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Use the following command to set up the repository
    echo -e \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo -e "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Intall Docker Engine
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl enable docker
    systemctl start docker

    # verify 
    docker version
}

f_KIND(){
    # https://kind.sigs.k8s.io/docs/user/quick-start/#installation 

    echo -e "$cyn \n######################### Installing kind -- $blu Kubernetes in Docker $end"
    sleep 2
    
    which kind   || echo -e "$yel Was already installed $end" && return
    
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.19.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
}

f_KUBECTL(){
    echo -e "$cyn \n######################### Installing kubectl $end"
    sleep 2

    which kubectl   || echo -e "$yel Was already installed $end" && return

    # Download the Google Cloud public signing key:
    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

    # Add the Kubernetes apt repository:
    echo -e "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    $PM update 2>/dev/null 1>/dev/null
    $PM install -y kubectl
}


f_KUBENS_KUBECTX(){
    echo -e "$cyn \n######################### kubens and kubectx $end"
    sleep 2
    which kubens ; which kubectx   || echo -e "$yel Was already installed $end" && return

    curl https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -o kubectx
    curl https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -o kubens
    chmod +x kube*
    mv kube* /usr/local/bin/
    # kubens -h   || echo -e "$red ERROR $end"
    # kubectx -h  || echo -e "$red ERROR $end"
}


f_TERRAFORM(){
    echo -e "$cyn \n######################### Terraform $end"
    sleep 2
    which terraform   || echo -e "$yel Was already installed $end" && return

    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo -e "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update 2>/dev/null 1>/dev/null && apt install terraform
    
    terraform version || echo -e "$red ERROR $end"
}


f_HELM(){
    echo -e "$cyn \n######################### helm $end"
    sleep 2
    # SNAP verison
    # https://github.com/snapcrafters/helm
    snap install helm --classic
    helm version || echo -e "$red ERROR $end"
}


f_END () {
    echo -e "$cyn \n######################### Installed software $end"

    echo -e "$cyn \n### Docker $end"
    which docker    || echo -e "$red Error, not installed"

    echo -e "$cyn \n### kubectl $end"
    which kubectl   || echo -e "$red Error, not installed"

    echo -e "$cyn \n### helm $end"
    which helm      || echo -e "$red Error, not installed"

    echo -e "$cyn \n### terraform $end"
    which terraform || echo -e "$red Error, not installed"

    echo -e "$cyn \n### kubens $end"
    which kubens    || echo -e "$red Error, not installed"

    echo -e "$cyn \n### kubectx $end"
    which kubectx   || echo -e "$red Error, not installed"
}
######################### START HERE

are_you_root

f_OS_SELECTOR
f_UPGRADE
f_GENERAL
f_DOCKER
f_KUBECTL
f_KUBENS_KUBECTX
f_TERRAFORM
f_HELM
f_END
