FROM quay.io/fedora/fedora-minimal

RUN /usr/bin/microdnf install -y perl-libwww-perl
COPY source /opt/dinaip
RUN ln -s /opt/dinaip/dinaip.pl /usr/sbin/dinaip

CMD eval /usr/sbin/dinaip -u $USERNAME -p $PASSWORD -a $ZONE; eval tail -f /var/log/dinaip.log
