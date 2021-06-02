# ======================================================================================================================
# ==========================================  DEVELOPMENT SERVICES  ====================================================
#                                       Setup mailhog & msendmail
#                   Mailhog offers a fake SMTP server and a browser based mailbox
#        In addition msendmail is installed. This program will forward calls to sendmail to mailhog.
#          And more importantly, it prevents developers from accidentally when accidentally using sendmail instead
#                of SMTP.  Many opensource quick start examples will send mail using sendmail.
#                   We don't need to worry about that when msendmail is properly configured.
#                      (See conf/php/msendmail.ini to see the required .ini changes)
# ======================================================================================================================

FROM alpine:3.4 AS mailhog-dev

# Install ca-certificates, required for the "release message" feature:
RUN apk --no-cache add \
    ca-certificates

# Install MailHog:
RUN apk --no-cache add --virtual build-dependencies \
    go \
    git \
  && mkdir -p /root/gocode \
  && export GOPATH=/root/gocode \
  && go get github.com/mailhog/MailHog \
  && go get github.com/mailhog/mhsendmail \
  && mv /root/gocode/bin/MailHog /usr/local/bin \
  && rm -rf /root/gocode \
  && apk del --purge build-dependencies

# Add mailhog user/group with uid/gid 1000.
# This is a workaround for boot2docker issue #581, see
# https://github.com/boot2docker/boot2docker/issues/581
RUN adduser -D -u 1000 mailhog

USER mailhog

WORKDIR /home/mailhog

ENTRYPOINT ["MailHog"]

# Expose the SMTP and HTTP ports:
EXPOSE 1025 8025