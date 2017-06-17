# run with -v /var/run/docker.sock:/var/run/docker.sock
FROM ubuntu

RUN apt-get -y update && \
    apt-get -y install curl wget iputils-ping dnsutils jq git zip python-pip vim && \
    rm -rf /var/lib/apt/lists/*

# Install Docker Client
RUN cd /tmp && \
    wget https://get.docker.com/builds/Linux/x86_64/docker-latest.tgz && \
    tar xvzf docker-latest.tgz && \
    mv docker/docker /bin && \
    curl -L "https://github.com/docker/compose/releases/download/1.8.1/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose && \
    chmod a+x /usr/local/bin/docker-compose && \
    echo "alias dockerps='docker ps -a --format "'"table {{.Names}}\t{{.ID}}\t{{.RunningFor}}\t{{.Status}}\t{{.Image}}"'"'" >> /root/.profile && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> /root/.profile && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> /root/.profile && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> /root/.profile && \
    rm -rf /tmp/docker*

# Install Kubernetes client
RUN cd /bin && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod a+x kubectl

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash && \
    . /root/.profile && \
    nvm install v8 && \
    npm install -g elasticdump

# # Install Ammonite
# RUN curl -L -o /usr/local/bin/amm https://git.io/vP4Gw && \
#     chmod +x /usr/local/bin/amm && \
#     mkdir -p ~/.ammonite ~daemon/.ammonite && \
#     curl -L -o ~/.ammonite/predef.sc https://git.io/v6r5y && \
#     cp ~/.ammonite/predef.sc ~daemon/.ammonite/ && \
#     chown -R daemon ~daemon/.ammonite && \
#     chmod -R 777 ~daemon/.ammonite

ENTRYPOINT ["/bin/bash", "-l"]
