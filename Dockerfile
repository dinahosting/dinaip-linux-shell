FROM alpine:3.7

MAINTAINER Rubén Cabrera Martínez <dev@rubencabrera.es>

RUN apk update && apk add perl
RUN apk add perl-libwww curl
COPY dinaip.conf /etc/dinaip.conf
ADD source /app
WORKDIR /app
RUN ["sh", "./install.sh"]
ENTRYPOINT ["./entrypoint.sh"]
