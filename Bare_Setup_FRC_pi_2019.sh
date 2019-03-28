###!/bin/bash -e
#
#BASE_DIR="/home/pi/FRCVision"
#WORK_DIR="$BASE_DIR/work"
#DEPLOY_DIR="$BASE_DIR/deploy"
#USE_QEMU="0"
#FIRST_USER_NAME="pi"
#FIRST_USER_PASS="raspberry"
#WPA_ESSID=
#WPA_PASSWORD=
#WPA_COUNTRY=
#IMG_NAME='FRCVision'
#ENABLE_SSH=1

#
# This all came from here Match 2019:
#
# https://github.com/wpilibsuite/FRCVision-pi-gen/
#

mkdir /home/pi/FRCVision
cd /home/pi/FRCVision

# 1)
# drag and drop all directories called files in the different stage
# subdirectories into one directory in the main directoy.

# 2) Update System
sudo apt-get update
sudo apt-get dist-upgrade -y
sudo apt-key add - < files/raspberrypi.gpg.key # not sure if this is needed

# 3) get the packages and apps
# Maybe these are needed
sudo apt-get -y install vim quilt qemu-user-static 
sudo apt-get -y install debootstrap zerofree pxz zip dosfstools
sudo apt-get -y install bsdtar libcap2-bin udev xz-utils python3 ant
# These are needed
sudo apt-get -y install build-essential cmake unzip pkg-config
sudo apt-get -y install libjpeg-dev libpng-dev libtiff-dev
sudo apt-get -y install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libavresample-dev
sudo apt-get -y install libxvidcore-dev libx264-dev
sudo apt-get -y install libgtk-3-dev
sudo apt-get -y install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
sudo apt-get -y install libcanberra-gtk*
sudo apt-get -y install libatlas-base-dev gfortran
sudo apt-get -y install python3-dev python3-numpy
sudo apt-get -y install python3-pybind11 python3-pip
sudo apt-get -y install libpython3 libpython3-dev
sudo apt-get -y install libusb-1.0-0-dev
sudo apt-get -y install swig
sudo apt-get -y install libopenblas-dev liblapacke-dev
sudo apt-get -y install galternatives openjdk-8-jdk

# 4)
# Install pip
cd ~
wget https://bootstrap.pypa.io/get-pip.py
sudo python3 get-pip.py

# 5) Install
# Python compiler
# picamera
# imutils
sudo pip3 install cython
sudo pip3 install "picamera[array]"
sudo pip3 install imutils

# 5) 
# Open JDK 11 from wpi
#
cd /home/pi/FRCVision
wget -nc -nv https://github.com/wpilibsuite/raspbian-openjdk/releases/download/v2019-11.0.1-1/jdk_11.0.1-strip.tar.gz
tar xzf jdk_11.0.1-strip.tar.gz \
    --exclude=\*.diz \
    --exclude=src.zip \
    --transform=s/^jdk/jdk-11.0.1/

sudo mv jdk-11.0.1 /usr/lib/jvm
sudo cp files/jdk-11.0.1.jinfo "/usr/lib/jvm/.jdk-11.0.1.jinfo"
sudo install -m 644 files/ld.so.conf.d/*.conf /etc/ld.so.conf.d
cd /usr/lib/jvm
sudo grep /usr/lib/jvm .jdk-11.0.1.jinfo | awk '{ print "update-alternatives --install /usr/bin/" \$2 " " \$2 " " \$3 " 2"; }' | bash
sudo update-java-alternatives -s jdk-11.0.1
sudo ldconfig

# 6)
# Build OpenCV
cd ~
wget -O opencv.zip https://github.com/opencv/opencv/archive/4.0.1.zip
wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.0.1.zip
unzip opencv.zip
unzip opencv_contrib.zip
mv opencv-4.0.1 opencv
mv opencv_contrib-4.0.1 opencv_contrib
cd ~/opencv
mkdir build
cd build
# tis uses TBB, NEON, VFPV3
cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D WITH_FFMPEG=OFF \
      -D WITH_TBB=ON \
      -D BUILD_TBB=ON \
      -D BUILD_JPEG=ON \
      -D BUILD_TESTS=OFF \
      -D BUILD_EXAMPLES=OFF \
      -D BUILD_JAVA=ON \
      -D BUILD_SHARED_LIBS=ON \
      -D BUILD_opencv_python3=ON \
      -D ENABLE_CXX11=ON \
      -D ENABLE_NEON=ON \
      -D ENABLE_VFPV3=ON \
      -D INSTALL_PYTHON_EXAMPLES=OFF \
      -D OPENCV_ENABLE_NONFREE=ON \
      -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
      -D PYTHON3_INCLUDE_PATH=/usr/include/python3.5m \
      -D PYTHON3_NUMPY_INCLUDE_DIRS=/usr/include/python3.5m/numpy \
      -D OPENCV_EXTRA_FLAGS_DEBUG=-Og \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D CMAKE_DEBUG_POSTFIX=d ..
sudo make -j3
sudo make install
sudo ldconfig
# not sure about following
cp -p /usr/local/share/opencv4/java/libopencv_java344*.so "/usr/local/lib/"
mkdir -p /usr/local/java
cp -p "/usr/local/share/opencv4/java/opencv-344.jar" "/usr/local/java/"

# 7)
# Install pynetworktables
cd /home/pi/FRCVision
wget -nc -nv -O pynetworktables.tar.gz https://github.com/robotpy/pynetworktables/archive/8a4288452be26e26dccad32980f46000e8d97928.tar.gz
tar xzf pynetworktables.tar.gz
mv pynetworktables-* pynetworktables
echo "__version__ = '2019.0.1'" > pynetworktables/ntcore/version.py
cd pynetworktables
pip3 install setuptools
python3 setup.py build
sudo python3 setup.py install
python3 setup.py clean


# 7)
# Raspbian toolchain
# NOT CHECKED YET
cd /home/pi/FRCVision
wget -nc -nv https://github.com/wpilibsuite/raspbian-toolchain/releases/download/v1.3.0/Raspbian9-Linux-Toolchain-6.3.0.tar.gz
tar xzf Raspbian9-Linux-Toolchain-*.tar.gz
export PATH=/home/pi/raspbian9/bin:${PATH}
export PKG_CONFIG_DIR=
export PKG_CONFIG_LIBDIR=${ROOTFS_DIR}/usr/lib/arm-linux-gnueabihf/pkgconfig:${ROOTFS_DIR}/usr/lib/pkgconfig:${ROOTFS_DIR}/usr/share/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${ROOTFS_DIR}

# 8)
# allwpilib
# NOT CHECKED YET
cd /home/pi/FRCVision
wget -nc -nv -O allwpilib.tar.gz https://github.com/wpilibsuite/allwpilib/archive/v2019.3.2.tar.gz
tar xzf allwpilib.tar.gz
mv allwpilib-* allwpilib
# Build wpiutil, cscore, ntcore, cameraserver
# always use the release version of opencv jar/jni
rm -rf $1
mkdir -p $1
pushd $1
cmake "${EXTRACT_DIR}/allwpilib" \
    -DWITHOUT_ALLWPILIB=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=/files/arm-pi-gnueabihf.toolchain.cmake \
    -DCMAKE_MODULE_PATH=/files \
    -DOPENCV_JAR_FILE=`ls ${ROOTFS_DIR}/usr/local/frc/java/opencv-344.jar` \
    -DOPENCV_JNI_FILE=`ls ${ROOTFS_DIR}/usr/local/frc/lib/libopencv_java344.so` \
    -DOpenCV_DIR=${ROOTFS_DIR}/usr/local/frc/share/OpenCV \
    -DTHREADS_PTHREAD_ARG=-pthread \
    -DCMAKE_INSTALL_PREFIX=/usr/local/frc \
make -j3


# 9)
# Install pybind11 submodule of robotpy-cscore
# NOT CHECKED YET
cd /home/pi/FRCVision
wget -nc -nv -O pybind11.tar.gz https://github.com/pybind/pybind11/archive/v2.2.tar.gz
rm -rf pybind11
tar xzf pybind11.tar.gz
mv pybind11-* pybind11
python3 setup.py build
sudo python3 setup.py install
python3 setup.py clean

# 10)
# Install robotpy-cscore
# NOT CHECKED YET
cd /home/pi/FRCVision
wget -nc -nv -O robotpy-cscore.tar.gz https://github.com/robotpy/robotpy-cscore/archive/2019.1.0.tar.gz
tar xzf robotpy-cscore.tar.gz"
mv robotpy-cscore-* robotpy-cscore
echo "__version__ = '2019.1.0'" > robotpy-cscore/cscore/version.py
#
# Build robotpy-cscore
# this build is pretty cpu-intensive, so we don't want to build it in a chroot,
# and setup.py doesn't support cross-builds, so build it manually
#
# Needs more stufff here 
# ...

# 11)
# pixy2
# NOIT CHECKED YET, DONT HAVE PIXY camera
cd /home/pi/FRCVision
wget -nc -nv -O pixy2.tar.gz https://github.com/charmedlabs/pixy2/archive/2adc6caba774a3056448d0feb0c6b89855a392f4.tar.gz
tar xzf pixy2.tar.gz
mv pixy2-* pixy2
rm -rf pixy2/releases
sed -i -e 's/^python/python3/;s/_pixy.so/_pixy.*.so/' pixy2/scripts/build_python_demos.sh
sed -i -e 's/print/#print/' pixy2/src/host/libpixyusb2_examples/python_demos/setup.py
cd pixy2/scripts
./build_libpixyusb2.sh
./build_python_demos.sh


# 12)
# NOT SURE ABOUT THIS
# NOT CHECKED YET
install -m 644 files/picamera.conf /etc/modules-load.d/
install -m 644 files/frc.json /boot/

