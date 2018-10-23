#!/bin/bash



docker build -t feeder . 
docker run -e "MQTT_HOST=192.168.1.3" -e "MQTT_PORT=1883" -e "PLATFORM=rpi" feeder 