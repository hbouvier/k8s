FROM node:8-alpine

# ADD https://github.com/hbouvier/watchgod/releases/download/v1.0.2/watchgod_v1.0.2.zip /tmp/
# 
# RUN apt-get -y update && \
#     apt-get -y install curl unzip && \
#     apt-get -y clean && \
#     cd /tmp && \
#     unzip watchgod_v1.0.2.zip && \
#     mv bin/linux_amd64/watchgod /bin/ && \
#     rm -rf bin watchgod_v1.0.2.zip && \
#     echo '{"Processes":[{"Name" : "bootstrap","Command" : ["node", "./bootstrap"]}]}' > /etc/watchgod.json

COPY ./bootstrap /app

WORKDIR /app

RUN npm install

# CMD watchgod -config /etc/watchgod.json boot

CMD node bootstrap
