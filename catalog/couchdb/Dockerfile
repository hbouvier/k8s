FROM ubuntu:trusty

RUN apt-get -y update && \
    apt-get -y install curl && \
    apt-get -y clean

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash && \
    . /root/.bashrc && \
    nvm install v7.2.0

# COPY ./clusterize.bash /bin/
# RUN chmod a+x /bin/clusterize.bash
# CMD /bin/bash -x /bin/clusterize.bash && while [ true ] ; do sleep 86400 ; done

COPY ./bootstrap /app/bootstrap
WORKDIR /app/bootstrap
RUN . /root/.bashrc && \
    npm install

CMD . /root/.bashrc && \
    node ./bootstrap
