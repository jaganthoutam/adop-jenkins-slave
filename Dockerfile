FROM centos:centos7.6.1810

# Swarm Env Variables (defaults)
ENV SWARM_MASTER=http://jenkins:8080/jenkins/
ENV SWARM_USER=jenkins
ENV SWARM_PASSWORD=jenkins

# Slave Env Variables
ENV SLAVE_NAME="Swarm_Slave"
ENV SLAVE_LABELS="docker aws ldap"
ENV SLAVE_MODE="exclusive"
ENV SLAVE_EXECUTORS=1
ENV SLAVE_DESCRIPTION="Core Jenkins Slave"

# Pre-requisites
RUN yum -y install epel-release
RUN yum install -y which \
    git \
    wget \
    tar \
    zip \
    unzip \
    openldap-clients \
    openssl \
    python-pip \
    systemd-219-62.el7_6.2.x86_64 \
    systemd-libs-219-62.el7_6.2.x86_64 \
    libxslt && \
    yum clean all 

RUN pip install awscli==1.10.19

# Docker versions Env Variables
ENV DOCKER_ENGINE_VERSION=1.10.3-1.el7.centos
ENV DOCKER_COMPOSE_VERSION=1.6.0
ENV DOCKER_MACHINE_VERSION=v0.6.0

RUN curl -fsSL https://get.docker.com/ | sed "s/docker-engine/docker-engine-${DOCKER_ENGINE_VERSION}/" | sh

RUN curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose
RUN curl -L https://github.com/docker/machine/releases/download/${DOCKER_MACHINE_VERSION}/docker-machine-`uname -s`-`uname -m` >/usr/local/bin/docker-machine && \
    chmod +x /usr/local/bin/docker-machine

# Install Java
ENV JAVA_HOME=/opt/openjdk-11
ENV PATH=$JAVA_HOME/bin:$PATH

ENV JAVA_VERSION=11.0.2
ENV JAVA_URL=https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz
ENV JAVA_SHA256=99be79935354f5c0df1ad293620ea36d13f48ec3ea870c838f20c504c9668b57

RUN set -eux; \
    \
    wget -O /openjdk.tgz "${JAVA_URL}"; \
    echo "${JAVA_SHA256} */openjdk.tgz" | sha256sum -c -; \
    mkdir -p "${JAVA_HOME}"; \
    tar --extract --file /openjdk.tgz --directory "${JAVA_HOME}" --strip-components 1; \
    rm /openjdk.tgz;
           
# Make Jenkins a slave by installing swarm-client
RUN curl -s -o /bin/swarm-client.jar -k http://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.8/swarm-client-3.8.jar

# Start Swarm-Client
CMD java -jar /bin/swarm-client.jar -executors ${SLAVE_EXECUTORS} -description "${SLAVE_DESCRIPTION}" -master ${SWARM_MASTER} -username ${SWARM_USER} -password ${SWARM_PASSWORD} -name "${SLAVE_NAME}" -labels "${SLAVE_LABELS}" -mode ${SLAVE_MODE}
