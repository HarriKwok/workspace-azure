FROM alpine:latest

#Install Stuff
RUN apk update && \ 
    apk add jq nano bash curl zsh git groff less rsync openssh-keygen openssh-client openssl python3 && \
    apk add --virtual=buildpak gcc libffi-dev musl-dev openssl-dev python3-dev make && \
    python3 -m ensurepip && \
    pip3 --no-cache-dir install -U pip && \
    pip3 install azure-cli && \
    pip3 install kube-shell && \
    pip3 install azure-shell  && \
    apk del --purge buildpak
    

RUN LATEST_TFVERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version') && \
    CURL_URL="https://releases.hashicorp.com/terraform/${LATEST_TFVERSION}/terraform_${LATEST_TFVERSION}_linux_amd64.zip" && \
    curl $CURL_URL -o /tmp/tf.zip && \
    unzip /tmp/tf.zip -d /usr/bin 

#Config zshell
RUN git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh && \
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc && \
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="af-magic"/' ~/.zshrc && \
    sed -i 's/root:\/bin\/ash/root:\/bin\/zsh/' /etc/passwd

#Create repo dir for mapping
RUN mkdir -p /root/repositories && cd /root/repositories

#Env vars for Kubernetes / Calico 
RUN echo "export DATASTORE_TYPE=kubernetes" >> /root/.bash_profile
RUN echo "export KUBECONFIG=~/.kube/config" >> /root/.bash_profile

#download stuff
RUN mkdir -p /root/tempstuffs && cd /root/tempstuffs
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
#apps stuff executable
RUN chmod +x ./kubectl 
#move stuff to /usr/local/bin
RUN mv ./kubectl /usr/local/bin

#install helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN chmod 700 get_helm.sh
RUN ./get_helm.sh

#install bash completion for kubectl autocomplete
RUN apk add bash-completion && \
    source <(kubectl completion bash) && \
    echo "source <(kubectl completion bash)" >> ~/.bashrc

WORKDIR /root

#docker build -t workspace-azure .
#docker run -it --rm --name workspace-azure -v "/c/Users/harri/workspaces":/root/Workspace workspace-azure zsh
#docker run -it --rm --name workspace-azure -v c:/workspace/:/root/workspace workspace-azure zsh 
