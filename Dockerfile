FROM osrf/ros:indigo-desktop
MAINTAINER David Watkins davidwatkins@cs.columbia.edu

ENV CATKIN_WS=/root/barrett_ws
ENV PYTHONPATH=$PYTHONPATH:/usr/lib/
RUN mkdir -p $CATKIN_WS/src
WORKDIR $CATKIN_WS/src

# download barrett_hand source
RUN git clone https://github.com/CRLab/barrett_hand.git -b kinetic-devel && \
    git clone https://github.com/RobotnikAutomation/pcan_python.git

# Install apt dependencies
RUN apt-get update && \
    apt-get install -y \
        python-catkin-tools \
        swig \ 
        gcc \
        wget \
        build-essential \
        cmake \
        libpopt-dev \
        linux-headers-generic \ 
        nano \
        software-properties-common \
        less && \
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test && \
    apt-get update && \
    apt-get install -y gcc-4.9 g++-4.9 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-4.9 && \
    # rosdep install -y --from-paths . --ignore-src --rosdistro ${ROS_DISTRO} && \
    rm -rf /var/lib/apt/lists/*

# Download peak linux driver
RUN wget https://www.peak-system.com/fileadmin/media/linux/files/peak-linux-driver-7.15.2.tar.gz && \
    tar -xvf peak-linux-driver-7.15.2.tar.gz && \
    cd peak-linux-driver-7.15.2 && \
    make -j$(($(nproc) + 1)) NET=NO_NETDEV_SUPPORT RT=NO_RT && \
    sudo make install

# HACK, replacing shell with bash for later docker build commands
RUN mv /bin/sh /bin/sh-old && \
    ln -s /bin/bash /bin/sh

# build repo
WORKDIR $CATKIN_WS/src/pcan_python
RUN sudo make install

# build repo
WORKDIR $CATKIN_WS
RUN source /ros_entrypoint.sh && \
    catkin build --no-status

# CMD [ "roslaunch", "bhand_controller bhand_controller.launch" ]

# This is how to run this, however I could not get the PCAN controller to register
# The -v flags are so that the docker instance can find the linux kernel headers to compile the peak linux driver
# ><
# docker run -it --rm \
#     --net host \
#     --privilged \
#     -v /usr/src:/usr/src \
#     -v /lib/modules:/lib/modules \
#     -v /linux-kernel:/linux-kernel \
#     crlab/barrett_hand_controller  