# cheeseball
Cheeseball is an overly complex cat feeder for my cat Cheddar. It's main purpose is to help me learn about microservice architecture, IoT, and Docker/Kubernetes


Architecture
============

Right now, Cheeseball will consist of the following services along with a client app that runs on a Raspberry Pi. 

* Feeder: handles all communication with the feeders themselves as well as feeder state
* Broker: serves as MQTT broker
* Owner: stores and provides user information
* Auth: authenticates users
* API: gateway to core services (feeder, owner)
* Web: UI, only talks to API
* Notifications: sends notifications via email
