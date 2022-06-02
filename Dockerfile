FROM --platform=linux/amd64 buildpack-deps:focal-scm

ARG CMAKE_VERSION=3.20.5
ARG ZSDK_VERSION=0.14.1
ARG SDK_NRF_VERSION=2.0.0
ARG WGET_ARGS="-q --show-progress --progress=bar:force:noscroll --no-check-certificate"
ARG HOSTTYPE=x86_64

# Setup environment
ENV DEBIAN_FRONTEND noninteractive
ENV TERM=xterm

# Add the Kitware APT repository
#RUN wget ${WGET_ARGS} https://apt.kitware.com/kitware-archive.sh && \
#	/bin/bash kitware-archive.sh && \
#	rm -f kitware-archive.sh

#Setup locale
RUN apt-get update && apt-get install -y --no-install-recommends \
		locales \
	  && rm -rf /var/lib/apt/lists/*
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV LANG=C.UTF-8

# Install needed packages
RUN apt-get update && apt-get install -y --no-install-recommends \
		ccache \
		device-tree-compiler \
		dfu-util \
		file \
		g++ \
		gcc \
		gcc-multilib \
		g++-multilib \
		git \
		gperf \
		lbzip2 \
		libc6-dev \
		libsdl2-dev \
		libgit2-dev \
		ninja-build \
		make \
		pkg-config \
		python3-dev \
		python3-pip \
		python3-setuptools \
		python3-tk \
		python3-wheel \
		unzip \
		wget \
		xz-utils \
		zip \
	  && rm -rf /var/lib/apt/lists/*

RUN wget ${WGET_ARGS} -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
  && chmod +x cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
  && ./cmake-${CMAKE_VERSION}-Linux-x86_64.sh --skip-license --prefix=/usr/local \
  && rm -f ./cmake-${CMAKE_VERSION}-Linux-x86_64.sh

RUN mkdir /opt/toolchains && cd /opt/toolchains && \
        wget ${WGET_ARGS} https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/zephyr-sdk-${ZSDK_VERSION}_linux-${HOSTTYPE}.tar.gz && \
        tar xf zephyr-sdk-${ZSDK_VERSION}_linux-${HOSTTYPE}.tar.gz && \
        zephyr-sdk-${ZSDK_VERSION}/setup.sh -c -t arm-zephyr-eabi && \
        rm zephyr-sdk-${ZSDK_VERSION}_linux-${HOSTTYPE}.tar.gz

ENV ZEPHYR_TOOLCHAIN_VARIANT zephyr
ENV ZEPHYR_SDK_INSTALL_DIR /opt/toolchains/zephyr-sdk-${ZSDK_VERSION}

RUN pip3 install --upgrade \
	pip==21.0.1 \
	setuptools==41.0.1 \
	wheel==0.33.4
RUN pip3 install --upgrade west

RUN mkdir -p /usr/src/ncs-${SDK_NRF_VERSION}
WORKDIR /usr/src/ncs-${SDK_NRF_VERSION}
RUN west init -m https://github.com/nrfconnect/sdk-nrf --mr v${SDK_NRF_VERSION} && \
	west update && \
	west zephyr-export

RUN pip3 install -r zephyr/scripts/requirements.txt && \
	pip3 install -r nrf/scripts/requirements.txt && \
	pip3 install -r bootloader/mcuboot/scripts/requirements.txt
