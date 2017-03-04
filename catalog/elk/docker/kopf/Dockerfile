FROM nginx:1.11-alpine

# RUN apk add --no-cache \
#        curl \
#        ca-certificates \
#        zsh \
#        unzip \
#        vim
# 
# ENV KOPF_VERSION 1.6.2
# ADD https://github.com/lmenezes/elasticsearch-kopf/archive/v${KOPF_VERSION}.zip /tmp/
# COPY ./kopf.conf /etc/nginx/conf.d
# RUN cd /tmp && \
#     unzip /tmp/v${KOPF_VERSION}.zip && \
#     mkdir -p /var/www/kopf && \
#     cp -R /tmp/elasticsearch-kopf-${KOPF_VERSION}/_site/* /var/www/kopf && \
#     chown -R nginx /var/www && \
#     rm -Rf /tmp/v${KOPF_VERSION}.zip /tmp/elasticsearch-kopf-${KOPF_VERSION} /etc/nginx/conf.d/defautl.conf




RUN apk add --no-cache \
       curl \
       ca-certificates \
       zsh \
       openssh \
       git \
       vim

COPY ./kopf.conf /etc/nginx/conf.d
RUN cd /tmp && \
    mkdir -p /var/www/kopf ~/.ssh && \
    ssh-keyscan -H github.com >> ~/.ssh/known_hosts && \
    git clone https://github.com/lmenezes/elasticsearch-kopf.git && \
    cp -R /tmp/elasticsearch-kopf/_site/* /var/www/kopf && \
    chown -R nginx /var/www && \
    rm -Rf /tmp/kopf /etc/nginx/conf.d/defautl.conf
