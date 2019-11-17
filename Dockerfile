FROM python:3-slim-buster

# Ansible Runtime Analysis Image for OpenShift Origin

LABEL io.k8s.description="ARA Collects and Archives Reports from Ansible." \
      io.k8s.display-name="ARA 1.2.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="ara,ansible,runtime,analysis,ara1,ara12,ara120" \
      io.openshift.non-scalable="false" \
      help="For more information visit https://github.com/Worteks/docker-ara" \
      maintainer="Samuel MARTIN MORO <sammar@worteks.com>" \
      version="1.2.0"

ENV DEBIAN_FRONTEND=noninteractive

COPY config/* /
RUN apt-get update \
    && if test "$DO_UPGRADE"; then \
	echo "# Upgrade Base Image"; \
	apt-get -y upgrade; \
	apt-get -y dist-upgrade; \
    fi \
    && mkdir -p /usr/share/man/man1 /usr/share/man/man7 \
    && apt-get install -y gcc python-dev libffi-dev libssl-dev \
	mariadb-client postgresql-client libpq-dev dumb-init \
    && pip install psycopg2 pymysql ara[server] \
    && if test "$DEBUG"; then \
	apt-get -y install curl psutils; \
    fi \
    && apt-get remove --purge -y gcc \
    && apt-get autoremove --purge -y \
    && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
    && mkdir -p /.ansible/tmp /.ara/server \
    && chmod -R 0775 /tmp /.ansible /.ara \
    && chown -R root:root /tmp /.ansible /.ara \
    && unset HTTP_PROXY HTTPS_PROXY NO_PROXY DO_UPGRADE http_proxy https_proxy

ENTRYPOINT ["dumb-init","--","/run-ara.sh"]
USER 1001
