###############################################################################
# AWSH Container - Vanilla AWSH Toolset
###############################################################################
FROM ubuntu:bionic

###############################################################################
# ARGs
###############################################################################
ARG HTTP_PROXY="${http_proxy}"
ARG http_proxy="${http_proxy}"
ARG HTTPS_PROXY="${https_proxy}"
ARG https_proxy="${https_proxy}"
ARG no_proxy="${no_proxy}"
ARG NO_PROXY="${NO_PROXY}"

ARG PRE_BUILD_PACKAGES="\
    apt-utils \
    build-essential \
    language-pack-en-base \
    software-properties-common \
    dirmngr \
    apt-transport-https \
    lsb-release \
    ca-certificates \
    curl"

ARG BUILD_PACKAGES="\
    gcc \
    locales \
    libkrb5-dev \
    libssl-dev \
    libffi-dev \
    python-dev \
    python3-dev \
    python3-requests-kerberos \
    python-simplejson \
    bash-completion"

ARG RUNTIME_PACKAGES="\
    bash \
    ca-certificates \
    coreutils \
    git \
    graphviz \
    grep \
    groff \
    jq \
    less \
    libc6 \
    libncurses5-dev \
    libncursesw5-dev \
    openssh-client \
    cl-ppcre \
    python \
    python-pip \
    python3.7 \
    python3-pip \
    sshpass \
    tar \
    util-linux \
    bsdmainutils \
    virtualenv \
    python3-virtualenv \
    krb5-user \
    vim \
    wget"

ARG RUBY_RUNTIME_PACKAGES="\
    ruby \
    ruby-bundler \
    ruby-dev \
    ruby-json \
    rake"

ARG SW_VER_TERRAFORMING="0.18.0"
ARG SW_VER_WEBRICK="1.6.0"
ARG SW_VER_FIXUID="0.4"

ARG AWSH_PYTHON3_DEPS="/tmp/requirements.python3"
ARG AWSH_PYTHON_DEPS="/tmp/requirements.python2"
ARG AWSH_PYTHON_EXTRAS="/tmp/requirements.extras"

###############################################################################
# ENVs
###############################################################################
ENV AWSH_ROOT /opt/awsh
ENV AWSH_USER_HOME /home/awsh
ENV AWSH_USER awsh
ENV AWSH_GROUP awsh
ENV PUID 1000
ENV PGID 1000
ENV PYTHONPATH /opt/awsh/lib/python
ENV PATH "/opt/awsh/bin:/opt/awsh/bin/tools:${PATH}:${AWSH_USER_HOME}/bin"
ENV AWSH_CONTAINER docker
ENV PATCHED_FONT_IN_USE no
ENV AWSH_VERSION_DOCKER latest
# Suppress command line queries for information, forces packages to install to defaults.
ENV DEBIAN_FRONTEND=noninteractive
# Set the env local for the docker image
ENV LANG en_US.UTF-8


###############################################################################
# LABELs
###############################################################################

# Add our dummy user and group
RUN adduser --disabled-password --quiet -u ${PUID} ${AWSH_USER}

# AWSH and AWS CLI paths
RUN mkdir -p ${AWSH_USER_HOME}/.awsh/log ${AWSH_ROOT}/tmp ${AWSH_USER_HOME}/.aws
COPY requirements/requirements.python2 ${AWSH_PYTHON_DEPS}
COPY requirements/requirements.extras ${AWSH_PYTHON_EXTRAS}
COPY requirements/requirements.python3 ${AWSH_PYTHON3_DEPS}

# Pre-Build os packages
RUN \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y ${PRE_BUILD_PACKAGES}

# Because Debian doesnt like to configure locale for docker for some aweful reason.. 
# we are forced to handle this by hand with Ubuntu docker locales set locally.
# https://stackoverflow.com/questions/28405902/how-to-set-the-locale-inside-a-debian-ubuntu-docker-container/28406007#28406007
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

# Build os packages
RUN \
    # install build support. needed for Kerberos installation
    apt-get install -y ${BUILD_PACKAGES} && \
    # install AWSH runtime packages
    apt-get install -y ${RUNTIME_PACKAGES}

# Build python packages
RUN \
    # install AWSH Python dependencies
    pip install -r ${AWSH_PYTHON_DEPS} --disable-pip-version-check && \
    pip install -r ${AWSH_PYTHON_EXTRAS} --disable-pip-version-check && \
    # python 3 should become the primary source for python dependencies sooner than later
    pip3 install -r ${AWSH_PYTHON3_DEPS} --disable-pip-version-check

# Build Ruby packages
RUN \
    # install ruby  (needed for terraforming tool)
    apt-get install -y ${RUBY_RUNTIME_PACKAGES} && \
    # RVM nolonger supports --no-rdoc and --no-ri, using new --no-document and set to users gem file
    echo 'gem: --no-document' >> ${AWSH_ROOT}/.gemrc && \
    gem install webrick --version ${SW_VER_WEBRICK} && \
    gem install terraforming --version ${SW_VER_TERRAFORMING}
    

# clean up apt packages and install
RUN apt-get purge
RUN apt-get autoclean


# Install diff-so-fancy (https://github.com/so-fancy/diff-so-fancy)
RUN \
    curl -SsL "https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy" -o /usr/local/bin/diff-so-fancy && \
    chown root:root /usr/local/bin/diff-so-fancy && \
    chmod 0755 /usr/local/bin/diff-so-fancy

# Install fixuid
RUN \
    curl -SsL "https://github.com/boxboat/fixuid/releases/download/v${SW_VER_FIXUID}/fixuid-${SW_VER_FIXUID}-linux-amd64.tar.gz" | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid

# Install SAM CLI
RUN pip3 install aws-sam-cli --disable-pip-version-check

# Install AWS SSM Session Manager tool
RUN \
    curl -SsL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o /tmp/session-manager-plugin.deb && \
    dpkg -i /tmp/session-manager-plugin.deb && \
    session-manager-plugin

# Get and Install Terraform 11 and 12 Binaries
RUN \
    curl -Ssl "https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip" -o /tmp/terraform12.zip && \
    curl -Ssl "https://releases.hashicorp.com/terraform/0.11.3/terraform_0.11.3_linux_amd64.zip" -o /tmp/terraform11.zip && \
    unzip -q /tmp/terraform12.zip -d /usr/local/bin/ && \
    mv /usr/local/bin/terraform /usr/local/bin/terraform12 && \
    unzip -q /tmp/terraform11.zip -d /usr/local/bin/

# Build the config for fixuid
COPY /lib/docker/fixuid.yml /etc/fixuid/config.yml

# Add our code
COPY / ${AWSH_ROOT}

# Link the JQ module library
RUN ln -s ${AWSH_ROOT}/lib/jq ${AWSH_USER_HOME}/.jq

# Ensure the AWSH lib is being loaded into the shell
RUN echo '. /opt/awsh/etc/awshrc' >> ${AWSH_USER_HOME}/.bashrc

# Build default AWS CLI config so that it doesn't have a brain fart when
# run due to not setting it's own sensible defaults
RUN { \
    echo '[default]' ; \
    echo 'output = json' ; \
    } | tee ${AWSH_USER_HOME}/.aws/config

RUN { \
    echo '[default]' ; \
    echo 'aws_access_key_id = 1' ; \
    echo 'aws_secret_access_key = 1' ; \
    } | tee ${AWSH_USER_HOME}/.aws/credentials

# Ensure ownership of AWSH paths
RUN \
    chown -c -R ${AWSH_USER}:${AWSH_GROUP} ${AWSH_ROOT} && \
    chown -c -R ${AWSH_USER}:${AWSH_GROUP} ${AWSH_USER_HOME}

WORKDIR ${AWSH_USER_HOME}

ENTRYPOINT ["/opt/awsh/lib/docker/entrypoint.sh"]

CMD ["/bin/bash", "-i"]

USER awsh
# USER ${AWSH_USER}:${AWSH_GROUP}
