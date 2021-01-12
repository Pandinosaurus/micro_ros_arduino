#!/bin/bash

PLATFORMS=()
while getopts "p:" o; do 
    case "$o" in
        p)
            PLATFORMS+=(${OPTARG})
            ;;
    esac
done

if [ $OPTIND -eq 1 ]; then 
    PLATFORMS+=("opencr1")
    PLATFORMS+=("teensy4")
    PLATFORMS+=("teensy32")
    PLATFORMS+=("teensy35")
    PLATFORMS+=("cortex_m0")
    PLATFORMS+=("cortex_m3")
fi

shift $((OPTIND-1))

######## Init ########

apt update 

cd /uros_ws

source /opt/ros/$ROS_DISTRO/setup.bash
source install/local_setup.bash

ros2 run micro_ros_setup create_firmware_ws.sh generate_lib

######## Copying Arduino placeholders XRCE transport ########

cp /arduino_project/extras/library_generation/arduino_xrce_transports/serial_transport_external.c firmware/mcu_ws/eProsima/Micro-XRCE-DDS-Client/src/c/profile/transport/serial/
cp /arduino_project/extras/library_generation/arduino_xrce_transports/serial_transport_external.h firmware/mcu_ws/eProsima/Micro-XRCE-DDS-Client/include/uxr/client/profile/transport/serial/

######## Adding extra packages ########
pushd firmware/mcu_ws > /dev/null

    # Workaround: Copy just tf2_msgs
    git clone -b foxy https://github.com/ros2/geometry2
    cp -R geometry2/tf2_msgs ros2/tf2_msgs
    rm -rf geometry2

    # Import user defined packages
    mkdir extra_packages
    pushd extra_packages > /dev/null
        cp -R /arduino_project/extras/library_generation/extra_packages/* .
        vcs import --input extra_packages.repos
    popd > /dev/null

popd > /dev/null

######## Clean and source ########
find /arduino_project/src/ ! -name micro_ros_arduino.h ! -name *.c ! -name *.cpp ! -name *.c.in -delete

######## Build for OpenCR  ########
if [[ " ${PLATFORMS[@]} " =~ " opencr1 " ]]; then
    rm -rf firmware/build

    export TOOLCHAIN_PREFIX=/uros_ws/gcc-arm-none-eabi-5_4-2016q2/bin/arm-none-eabi-
    ros2 run micro_ros_setup build_firmware.sh /arduino_project/extras/library_generation/opencr_toolchain.cmake /arduino_project/extras/library_generation/colcon.meta

    find firmware/build/include/ -name "*.c"  -delete
    cp -R firmware/build/include/* /arduino_project/src/ 

    mkdir -p /arduino_project/src/cortex-m7/fpv5-sp-d16-softfp
    cp -R firmware/build/libmicroros.a /arduino_project/src/cortex-m7/fpv5-sp-d16-softfp/libmicroros.a
fi

######## Build for SAMD (e.g. Arduino Zero) ########
if [[ " ${PLATFORMS[@]} " =~ " cortex_m0 " ]]; then
    rm -rf firmware/build

    export TOOLCHAIN_PREFIX=/uros_ws/gcc-arm-none-eabi-5_4-2016q3/bin/arm-none-eabi-
    ros2 run micro_ros_setup build_firmware.sh /arduino_project/extras/library_generation/cortex_m0_toolchain.cmake /arduino_project/extras/library_generation/colcon_verylowmem.meta

    find firmware/build/include/ -name "*.c"  -delete
    cp -R firmware/build/include/* /arduino_project/src/ 

    mkdir -p /arduino_project/src/cortex-m0plus
    cp -R firmware/build/libmicroros.a /arduino_project/src/cortex-m0plus/libmicroros.a
fi

######## Build for SAM (e.g. Arduino Due) ########
if [[ " ${PLATFORMS[@]} " =~ " cortex_m3 " ]]; then
    rm -rf firmware/build

    export TOOLCHAIN_PREFIX=/uros_ws/gcc-arm-none-eabi-4_8-2014q1/bin/arm-none-eabi-
    ros2 run micro_ros_setup build_firmware.sh /arduino_project/extras/library_generation/cortex_m3_toolchain.cmake /arduino_project/extras/library_generation/colcon_lowmem.meta

    find firmware/build/include/ -name "*.c"  -delete
    cp -R firmware/build/include/* /arduino_project/src/ 

    mkdir -p /arduino_project/src/cortex-m3
    cp -R firmware/build/libmicroros.a /arduino_project/src/cortex-m3/libmicroros.a
fi

######## Build for Teensy 3.2 ########
if [[ " ${PLATFORMS[@]} " =~ " teensy32 " ]]; then
    rm -rf firmware/build

    export TOOLCHAIN_PREFIX=/uros_ws/gcc-arm-none-eabi-5_4-2016q3/bin/arm-none-eabi-
    ros2 run micro_ros_setup build_firmware.sh /arduino_project/extras/library_generation/teensy32_toolchain.cmake /arduino_project/extras/library_generation/colcon_lowmem.meta

    find firmware/build/include/ -name "*.c"  -delete
    cp -R firmware/build/include/* /arduino_project/src/ 

    mkdir -p /arduino_project/src/mk20dx256
    cp -R firmware/build/libmicroros.a /arduino_project/src/mk20dx256/libmicroros.a
fi

######## Build for Teensy 3.5 ########
if [[ " ${PLATFORMS[@]} " =~ " teensy35 " ]]; then
    rm -rf firmware/build

    export TOOLCHAIN_PREFIX=/uros_ws/gcc-arm-none-eabi-5_4-2016q3/bin/arm-none-eabi-
    ros2 run micro_ros_setup build_firmware.sh /arduino_project/extras/library_generation/teensy35_toolchain.cmake /arduino_project/extras/library_generation/colcon_lowmem.meta

    find firmware/build/include/ -name "*.c"  -delete
    cp -R firmware/build/include/* /arduino_project/src/ 

    mkdir -p /arduino_project/src/mk64fx512/fpv4-sp-d16-hard
    cp -R firmware/build/libmicroros.a /arduino_project/src/mk64fx512/fpv4-sp-d16-hard/libmicroros.a
fi

######## Build for Teensy 4 ########
if [[ " ${PLATFORMS[@]} " =~ " teensy4 " ]]; then
    rm -rf firmware/build

    export TOOLCHAIN_PREFIX=/uros_ws/gcc-arm-none-eabi-5_4-2016q3/bin/arm-none-eabi-
    ros2 run micro_ros_setup build_firmware.sh /arduino_project/extras/library_generation/teensy4_toolchain.cmake /arduino_project/extras/library_generation/colcon.meta

    find firmware/build/include/ -name "*.c"  -delete
    cp -R firmware/build/include/* /arduino_project/src/ 

    mkdir -p /arduino_project/src/imxrt1062/fpv5-d16-hard
    cp -R firmware/build/libmicroros.a /arduino_project/src/imxrt1062/fpv5-d16-hard/libmicroros.a
fi

######## Generate extra files ########
find firmware/mcu_ws/ros2 \( -name "*.srv" -o -name "*.msg" -o -name "*.action" \) | awk -F"/" '{print $(NF-2)"/"$NF}' > /arduino_project/available_ros2_types
find firmware/mcu_ws/extra_packages \( -name "*.srv" -o -name "*.msg" -o -name "*.action" \) | awk -F"/" '{print $(NF-2)"/"$NF}' >> /arduino_project/available_ros2_types

cd firmware
echo "" > /arduino_project/built_packages
for f in $(find $(pwd) -name .git -type d); do pushd $f > /dev/null; echo $(git config --get remote.origin.url) $(git rev-parse HEAD) >> /arduino_project/built_packages; popd > /dev/null; done;