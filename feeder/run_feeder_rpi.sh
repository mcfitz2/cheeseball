#!/bin/bash
HARDWARE=$(cat /proc/cpuinfo |grep Hardware|awk '{print $3}')
REVISION=$(cat /proc/cpuinfo |grep Revision|awk '{print $3}')
SERIAL=$(cat /proc/cpuinfo |grep Serial|awk '{print $3}')
UID=$(echo $HARDWARE$REVISION$SERIAL|base64)


if [ "$1" = "build" ]; then
	docker build -t feeder . 
fi
docker run --privileged -d -e "UID=$UID" -e "MQTT_HOST=micahf.com" -e "MQTT_PORT=1883" -e "PLATFORM=rpi" feeder 
