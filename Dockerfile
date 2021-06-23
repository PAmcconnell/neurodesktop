FROM ubuntu:20.04

# Install locale and set
RUN apt-get update &&            \
    apt-get install -y           \
      locales &&                 \
    apt-get clean &&             \
    rm -rf /var/lib/apt/lists/*
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install dependancies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    wget openjdk-11-jdk make gcc g++ libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libvncserver-dev libtelnet-dev libssl-dev libvorbis-dev libwebp-dev && \
    rm -rf /var/lib/apt/lists/*

# Install Apache Tomcat
ARG TOMCAT_REL="9"
ARG TOMCAT_VERSION="9.0.48"
RUN wget https://www.strategylions.com.au/mirror/tomcat/tomcat-${TOMCAT_REL}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -P /tmp && \
    tar -xf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /tmp && \
    mv /tmp/apache-tomcat-${TOMCAT_VERSION} /usr/local/tomcat && \
    mv /usr/local/tomcat/webapps /usr/local/tomcat/webapps.dist && \
    mkdir /usr/local/tomcat/webapps && \
    sh -c 'chmod +x /usr/local/tomcat/bin/*.sh'

# Install Apache Guacamole
ARG GUACAMOLE_VERSION="1.3.0"
WORKDIR /etc/guacamole
RUN wget "https://www.strategylions.com.au/mirror/guacamole/${GUACAMOLE_VERSION}/binary/guacamole-1.3.0.war" -O /usr/local/tomcat/webapps/ROOT.war && \
    wget "https://www.strategylions.com.au/mirror/guacamole/${GUACAMOLE_VERSION}/source/guacamole-server-1.3.0.tar.gz" -O /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz && \
    tar xvf /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz && \
    cd /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION} && \
   ./configure --with-init-dir=/etc/init.d &&   \
    make &&                            \
    make install &&                             \
    ldconfig &&                                 \
    rm -r /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}*

# Create Guacamole configurations
RUN echo "user-mapping: /etc/guacamole/user-mapping.xml" > /etc/guacamole/guacamole.properties && \
    touch /etc/guacamole/user-mapping.xml

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    sudo libxt6 openssh-server libvncserver-dev && \
    rm -rf /var/lib/apt/lists/*

ARG    TURBOVNC_VERSION="2.2.6"
RUN wget "https://sourceforge.net/projects/turbovnc/files/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb/download" -O /opt/turbovnc.deb && \
    dpkg -i /opt/turbovnc.deb && \
    rm -f /opt/turbovnc.deb

# Create user account with password-less sudo abilities
RUN useradd -s /bin/bash -g 100 -G sudo -m user && \
    /usr/bin/printf '%s\n%s\n' 'password' 'password'| passwd user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/user/Desktop

COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

COPY user-mapping.xml /etc/guacamole/user-mapping.xml

ENV    RES "1920x1080"
EXPOSE 8080

USER 1000:100

ENTRYPOINT sudo -E /startup.sh