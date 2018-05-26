FROM alpine:3.7

MAINTAINER Rubén Cabrera Martínez <dev@rubencabrera.es>

RUN apk update && apk add perl
RUN apk add perl-libwww
ADD source /app
WORKDIR /app
RUN ["sh", "./install.sh"]
CMD ["dinaip"]
