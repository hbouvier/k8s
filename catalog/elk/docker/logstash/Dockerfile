FROM logstash:2.3

ADD https://github.com/hbouvier/watchgod/releases/download/v1.0.2/watchgod_v1.0.2.zip /tmp/
ADD http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz /etc/logstash/geoip-database/
RUN cd /etc/logstash/geoip-database && \
    gunzip GeoLiteCity.dat.gz && \
    chmod a+r /etc/logstash/geoip-database/GeoLiteCity.dat && \
    logstash-plugin install logstash-input-beats && \
    cd /tmp && \
    unzip watchgod_v1.0.2.zip && \
    mv bin/linux_amd64/watchgod /bin/ && \
    rm -rf bin watchgod_v1.0.2.zip && \
    echo '{"Processes":[{"Name" : "logstash","Command" : ["/opt/logstash/bin/logstash", "-f", "/config-dir/logstash.conf", "--auto-reload"]}]}' > /etc/watchgod.json

VOLUME /config-dir/

CMD watchgod -config /etc/watchgod.json boot
