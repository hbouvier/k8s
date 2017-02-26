FROM rabbitmq:3.6.6-management
ADD ./bin/ /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["rabbitmq-server"]