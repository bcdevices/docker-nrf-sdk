FROM buildpack-deps:bionic-scm

# Setup environment
ENV DEBIAN_FRONTEND noninteractive
ENV TERM=xterm

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
		device-tree-compiler >= 1.4.6 \
		dfu-util \
		file \
		g++ \
		gcc \
		gcc-multilib \
		git \
		gperf \
		lbzip2 \
		libc6-dev \
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

ENV CMAKE_VERSION 3.13.3
RUN wget -q https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-Linux-x86_64.sh \
  && chmod +x cmake-$CMAKE_VERSION-Linux-x86_64.sh \
  && ./cmake-$CMAKE_VERSION-Linux-x86_64.sh --skip-license --prefix=/usr/local \
  && rm -f ./cmake-$CMAKE_VERSION-Linux-x86_64.sh

ENV GNUARM_DIR 8-2019q3/RC1.1
ENV GNUARM_VERSION 8-2019-q3-update
RUN wget -q https://developer.arm.com/-/media/Files/downloads/gnu-rm/$GNUARM_DIR/gcc-arm-none-eabi-$GNUARM_VERSION-linux.tar.bz2 \
  && tar -xjf gcc-arm-none-eabi-$GNUARM_VERSION-linux.tar.bz2 -C /opt \
  && rm -f gcc-arm-none-eabi-$GNUARM_VERSION-update-linux.tar.bz2

RUN pip3 install --upgrade \
	pip==19.2.3 \
	setuptools==41.0.1 \
	wheel==0.33.4
RUN pip3 install west

RUN mkdir -p /usr/src/ncs
WORKDIR /usr/src/ncs
RUN west init -m https://github.com/nrfconnect/sdk-nrf --mr v1.3.1 && \
	west update && \
	west zephyr-export
WORKDIR /usr/src/ncs/nrf
RUN git checkout v1.3.1 && west update
WORKDIR /usr/src/ncs
RUN pip3 install -r zephyr/scripts/requirements.txt && \
	pip3 install -r nrf/scripts/requirements.txt && \
	pip3 install -r bootloader/mcuboot/scripts/requirements.txt

RUN wget -q https://launchpad.net/ubuntu/+source/device-tree-compiler/1.4.7-1/+build/15279267/+files/device-tree-compiler_1.4.7-1_amd64.deb && \
        apt install ./device-tree-compiler_1.4.7-1_amd64.deb && \
        rm -f device-tree-compiler_1.4.7-1_amd64.deb

ENV ZEPHYR_TOOLCHAIN_VARIANT="gnuarmemb"
ENV GNUARMEMB_TOOLCHAIN_PATH="/opt/gcc-arm-none-eabi-8-2019-q3-update"
