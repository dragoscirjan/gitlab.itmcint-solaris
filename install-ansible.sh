#! /bin/sh

install_with_apt_get() {
    apt-add-repository -y ppa:ansible/ansible
    apt-get update
    apt-get install -y ansible
}

install_with_brew() {
    # https://hvops.com/articles/ansible-mac-osx/
    brew install ansible ansible-lint
}

configure_etc_hosts() {
    cat > /etc/ansible/hosts <<EOF

EOF
}

which apt-get > /dev/null \
    && install_with_apt_get
    
which brew > /dev/null \
    && install_with_brew