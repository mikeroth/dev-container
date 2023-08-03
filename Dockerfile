FROM bitnami/minideb:latest-amd64 AS base

ENV TZ=America/Los_Angeles \
    DEBIAN_FRONTEND=noninteractive \
    EDITOR=vim \
    USER=Neo \
    USER_HOME=/home/Neo \
    VAULT_ADDRESS="<address to your Vault instance>"

USER root

# Add non-root user '${USER}' and create necessary directories
RUN useradd --create-home --shell /bin/bash $USER
WORKDIR $USER_HOME

# Install necessary packages, add non-root user and install ZSH
RUN apt-get update -y \
    && apt-get dist-upgrade -y \
    && apt-get install -y \
        fzf \
        git \
        jq \
        yq \
        locales \
        vim \
        neovim \
        default-mysql-client \
        postgresql-client \
        python3 \
        python3-pip \
        python3-venv \
        python3-openssl \
        screen \
        tmux \
        sshpass \
        telnet \
        iputils-ping \
        traceroute \
        nmap \
        dnsutils \
        tree \
        unzip \
        curl \
        wget \
        rsync \
        zip \
        zsh \
        sudo \
        make \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        llvm \
        libncurses5-dev \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libffi-dev \
        liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure timezone and localization
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen en_US.UTF-8

FROM base AS builder

ARG VAULT_VERSION=1.13.0
ARG PACKER_VERSION=1.7.0
ARG TF_VERSION=1.5.4
ARG TG_VERSION=0.48.4
ARG CHEAT_VERSION=4.4.0
ARG KUBECTL_VERSION=v1.27.4
ARG KUBECOLOR_VERSION=0.0.21
ARG HELM_VERSION=v3.12.2
ARG K9_VERSION=v0.27.4

# Install vault
RUN curl -fsL "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip" -o vault.zip \
    && unzip vault.zip -d /usr/local/bin \
    && rm vault.zip \
    && chmod 0755 /usr/local/bin/vault

# Install packer
RUN curl -fsL "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" -o packer.zip \
    && unzip packer.zip \
    && rm packer.zip \
    && mv packer /usr/local/bin/packer

# Install tfswitch
RUN curl -L "https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh" | INSTALL_DIR=$HOME/bin bash
USER $USER
RUN tfswitch $TF_VERSION

# Install tgswitch
USER root
RUN curl -L "https://raw.githubusercontent.com/warrensbox/tgswitch/release/install.sh" -o install_tgswitch.sh
RUN sed -i 's|/usr/local/bin|$USER_HOME/bin|g' install_tgswitch.sh
ENV PATH="$USER_HOME/bin:${PATH}"
RUN bash install_tgswitch.sh \
    && rm -f install_tgswitch.sh
USER $USER
RUN tgswitch $TG_VERSION \
    && mkdir -p "$HOME/.terraform.d/plugin-cache" \
    && printf "plugin_cache_dir   = \"$HOME/.terraform.d/plugin-cache\"\ndisable_checkpoint = true\n" > $USER_HOME/.terraformrc

# Install AWS CLI
USER root
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Install Cheat
RUN sudo -u ${USER} mkdir -p \
    /home/${USER}/.config/cheat/cheatsheets/personal \
    /home/${USER}/.config/cheat/cheatsheets/community
RUN curl -L "https://github.com/cheat/cheat/releases/download/${CHEAT_VERSION}/cheat-linux-amd64.gz" -o /usr/local/bin/cheat.gz \
    && gunzip /usr/local/bin/cheat.gz \
    && chmod +x /usr/local/bin/cheat

# Install kubectl
RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/bin/kubectl

# Install kubercolor
RUN curl -fsL "https://github.com/kubecolor/kubecolor/releases/download/v${KUBECOLOR_VERSION}/kubecolor_${KUBECOLOR_VERSION}_Linux_x86_64.tar.gz" \
        | tar -xz -C /usr/local/bin/ \
    && chmod +x /usr/local/bin/kubecolor \
    && rm -f /usr/local/bin/kubecolor_$KUBECOLOR_VERSION_Linux_x86_64.tar.gz

# Install helm
RUN curl -L -o helm-$HELM_VERSION-linux-amd64.tar.gz "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
    && tar -xzf helm-$HELM_VERSION-linux-amd64.tar.gz --strip-components=1 linux-amd64/helm \
    && mv helm /usr/bin/ \
    && rm helm-$HELM_VERSION-linux-amd64.tar.gz

# Install kustomize
RUN curl -sSL "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" -o /usr/bin/kustomize \
    && chmod +x /usr/bin/kustomize

# Install K9s
RUN curl -sSL -o k9s_Linux_amd64.tar.gz "https://github.com/derailed/k9s/releases/download/${K9_VERSION}/k9s_Linux_amd64.tar.gz" \
    && tar -xzf k9s_Linux_amd64.tar.gz -C /usr/local/bin/ k9s \
    && rm k9s_Linux_amd64.tar.gz

# Install Pyenv
RUN git clone https://github.com/pyenv/pyenv.git ${USER_HOME}/.pyenv

# Install Golang
RUN wget https://go.dev/dl/go1.20.6.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.20.6.linux-amd64.tar.gz \
    && rm -rf go1.20.6.linux-amd64.tar.gz

# Install Vault AWS Creds
RUN git clone https://github.com/jantman/vault-aws-creds.git \
    && mv vault-aws-creds/vault-aws-creds.py /usr/bin/ \
    && chmod 0755 /usr/bin/vault-aws-creds.py

FROM base AS workstation

COPY --from=builder /usr/local/bin/vault /usr/local/bin/vault
COPY --from=builder /usr/local/bin/packer /usr/local/bin/packer
COPY --from=builder /usr/local/bin/tfswitch /usr/local/bin/tfswitch
COPY --from=builder /home/Neo/bin/tgswitch /user/local/bin/tgswitch
COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder /usr/local/bin/cheat /usr/local/bin/cheat
COPY --chown=${USER}:${USER} cheats/* ${USER_HOME}/.config/cheat/cheatsheets/personal/
COPY --from=builder /usr/bin/kubectl /usr/bin/kubectl
COPY --from=builder /usr/local/bin/kubecolor /usr/local/bin/kubecolor
COPY --from=builder /usr/bin/helm /usr/bin/helm
COPY --from=builder /usr/bin/kustomize /usr/bin/kustomize
COPY --from=builder /usr/local/bin/k9s /usr/local/bin/k9s
COPY --from=builder --chown=$USER:$USER ${USER_HOME}/.pyenv ${USER_HOME}/.pyenv
COPY --from=builder /usr/local/bin/vault /usr/local/bin/vault
COPY --chown=$USER:$USER vimrc $USER_HOME/.vimrc
COPY --chown=$USER:$USER aliases $USER_HOME/.aliases
COPY --from=builder /usr/local/go /usr/local/go

USER root

# Config Cheat
RUN cheat | yes \
    | sudo -u Neo cheat

# Install ZSH/Powerline Fonts
RUN curl -fsSL "https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh" \
        | sudo -u ${USER} zsh \
    && sed -i -e 's/robbyrussell/agnoster/' ${USER_HOME}/.zshrc \
    && git clone --depth=1 https://github.com/powerline/fonts.git \
    && ./fonts/install.sh \
    && rm -rf fonts

# Setup Solarized colorized theme to vim
USER $USER
RUN mkdir -p ${HOME}/.vim/colors \
    && curl -L https://github.com/altercation/vim-colors-solarized/archive/refs/heads/master.tar.gz \
       | tar xz --strip-components=2 -C ${HOME}/.vim/colors vim-colors-solarized-master/colors/solarized.vim

# Add plugins to zshrc - https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins
RUN sed -i "s/plugins=.*/plugins=(git gh kubectl)/g" ${HOME}/.zshrc \
    && echo 'source $HOME/.aliases' >> ${HOME}/.zshrc

# Configure terraform plugin caching
RUN mkdir -p ${HOME}/.terraform.d/plugin-cache \
    && printf "plugin_cache_dir   = \"${HOME}/.terraform.d/plugin-cache\"\ndisable_checkpoint = true\n" > $HOME/.terraformrc

# ZSHRC Kubecolor & Kubectl Autocompletion
RUN echo "compdef kubecolor=kubectl" >> $HOME/.zshrc \
    && echo 'source <(kubectl completion zsh)' >> $HOME/.zshrc

# Pyenv Config
RUN echo 'export PYENV_ROOT="${HOME}/.pyenv"' >> $HOME/.zshrc \
    && echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> $HOME/.zshrc \
    && echo 'eval "$(pyenv init -)"' >> $HOME/.zshrc \
    && echo EDITOR=vim >> $HOME/.zshrc \
    && /home/Neo/.pyenv/bin/pyenv install 3.11.4
    # Switch to 3.11.4
    # poetry pylint Flask Django

# Install tldr request
RUN python3 -m venv /venv \
    && /venv/bin/pip install requests tldr
ENV PATH="/venv/bin:$PATH"

# Install Golang
USER root
RUN wget https://go.dev/dl/go1.20.6.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.20.6.linux-amd64.tar.gz \
    && echo "export PATH=$PATH:/usr/local/go/bin" >> $USER_HOME/.zshrc \
    && rm -rf go1.20.6.linux-amd64.tar.gz

# Vault AWS Creds Config
RUN echo "export VAULT_ADDR=${VAULT_ADDRESS}" >> $USER_HOME/.zshrc \
    echo "eval $(vault-aws-creds.py -w)" >> $USER_HOME/.zshrc \
    && touch /var/log/vault-login.log \
    && chown $USER:$USER /var/log/vault-login.log \
    && echo 'vault-ssh() {' >> $USER_HOME/.zshrc \
    && echo ' vault ssh -mount-point=ssh/$1 -role otp_key_role -strict-host-key-checking=no -user-known-hosts-file=/dev/null $2' >> $USER_HOME/.zshrc \
    && echo '}' >> $USER_HOME/.zshrc

# Configure Golang
RUN echo "export PATH=$PATH:/usr/local/go/bin" >> $USER_HOME/.zshrc

USER $USER

CMD ["/usr/bin/zsh", "-l"]