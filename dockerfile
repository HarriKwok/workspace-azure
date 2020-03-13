FROM alpine:3.9

#Install Stuff
RUN apk update && \ 
    apk add jq nano bash curl zsh git groff less rsync openssh-keygen openssh-client openssl && \
    apk add py-pip  && \
    apk add --virtual=buildpak gcc libffi-dev musl-dev openssl-dev python-dev make && \
    pip --no-cache-dir install -U pip && \
    pip install azure-cli && \
    pip install kube-shell && \
    pip install azure-shell  && \
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
RUN curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > ./install-helm.sh
RUN chmod u+x ./install-helm.sh
RUN ./install-helm.sh

WORKDIR /root

#docker build -t workspace-azure .
#docker run -it --rm --name workspace-azure -v "/c/Users/harri/workspaces":/root/Workspace workspace-azure zsh
#docker run -it --rm --name workspace-azure -v c:/workspace/:/root/workspace workspace-azure zsh 
