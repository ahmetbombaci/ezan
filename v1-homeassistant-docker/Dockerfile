FROM alpine
WORKDIR /script

RUN apk add bash curl at jq

COPY ./script/* /script/

COPY ./script/crontab /var/spool/cron/crontabs/root

RUN chmod +x /script/ezan-job

CMD /usr/sbin/crond -f -l 2 -L /var/log/cron.log

#keep container running
#CMD tail -f /dev/null
