#!/bin/bash


if [ "$1" = "build" ]; then
	docker build -t feeder . 
fi
docker run --privileged -e "MQTT_HOST=micahf.com" -e "MQTT_PORT=1883" -e "PLATFORM=rpi" feeder 

