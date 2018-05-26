FROM alpine:3.7

MAINTAINER Rubén Cabrera Martínez <dev@rubencabrera.es>

RUN apk update && apk add perl
RUN apk add perl-libwww curl
ADD source /app
WORKDIR /app
RUN ["sh", "./install.sh"]
ENTRYPOINT ["./entrypoint.sh"]
