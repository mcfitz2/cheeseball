import time, sys, os
if os.environ.get('PLATFORM', None) == 'rpi':
	import RPi.GPIO as GPIO
from random import randint
import paho.mqtt.client as mqtt
import json





class FeedMechDummy(object):
	def __init__(self):
		self.step_pin = 23
		self.dir_pin = 24
		self.home_pin = 25
		self.FORWARD = True
		self.BACKWARD = False
		self.steps_per_division = 80

	def step(self, direction):
		pass

	def home(self):
		print("Found home")
		print("Backed off. home pin is ")
	def forward(self, divisions):
		for i in range(self.steps_per_division*divisions):
			self.step(self.FORWARD)


class FeedMech(object):
	def __init__(self):
		self.step_pin = 23
		self.dir_pin = 24
		self.home_pin = 25
		self.FORWARD = True
		self.BACKWARD = False
		self.steps_per_division = 80

		GPIO.setmode(GPIO.BCM) # Broadcom pin-numbering scheme
		GPIO.setup(self.step_pin, GPIO.OUT) # LED pin set as output
		GPIO.setup(self.dir_pin, GPIO.OUT) # PWM pin set as output
		GPIO.setup(self.home_pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)

	def step(self, direction):
		GPIO.output(self.dir_pin, GPIO.LOW if direction == self.FORWARD else GPIO.HIGH)
		GPIO.output(self.step_pin, GPIO.HIGH)
		time.sleep(0.001)
		GPIO.output(self.step_pin, GPIO.LOW)

	def home(self):
		GPIO.output(self.dir_pin, GPIO.HIGH)
		while GPIO.input(self.home_pin) == GPIO.HIGH:
			self.step(self.BACKWARD)
		print("Found home")
		GPIO.output(self.dir_pin, GPIO.LOW)
		while True:
			self.step(self.BACKWARD)
			if GPIO.input(self.home_pin) == GPIO.HIGH:
				break
		print("Backed off. home pin is ", GPIO.input(self.home_pin) == GPIO.LOW)
	def forward(self, divisions):
		for i in range(self.steps_per_division*divisions):
			self.step(self.FORWARD)
	def measure(self):
		self.home()
		steps = 0
		while GPIO.input(self.home_pin) == GPIO.HIGH:
			self.step(self.FORWARD)
			steps+=1
		while GPIO.input(self.home_pin) == GPIO.LOW:
			self.step(self.FORWARD)
			steps+=1
		print(steps)


class Feeder(mqtt.Client):
	def __init__(self, uid="tester", mech=None, host="broker", port=1883):
		mqtt.Client.__init__(self, uid)
		self.uid = uid
		self.mech = mech
		self.connect(host, port, 60)
		self.subscribe("feeders/"+self.uid+"/#", 0)
		self.callbacks = {
			"feed_requested":self.feed, 
			"heartbeat":self.heartbeat,
		}
	def _build_topic(self, event_name):
		return "feeders/"+self.uid+"/"+event_name
	def feed(self, topic, message):
		print("Feeding %d cups" % message["cups"])
		self.mech.forward(message["cups"])
		self.publish(self._build_topic("feeding_complete"), json.dumps({}))
	def heartbeat(self, topic, message):
		self.publish(self._build_topic("heartbeat"), json.dumps({"status":"GOOD"}))
	def snapshot(self, topic, message):
		self.publish(self._build_topic("snapshot_complete "), json.dumps({"status":"GOOD"}))
	def on_connect(self, client, obj, flags, rc):
	    pass
	    #print("rc: " + str(rc))
	def on_message(self, client, obj, msg):
	    print(msg.topic + " " + str(msg.qos) + " " + str(msg.payload))
	    message = json.loads(msg.payload.decode('utf-8'))
	    try:
	    	uid, topic = msg.topic.split("/")
	    	cb = self.callbacks.get(topic)
	    	if cb:
	    		cb(msg.topic, message)
	    except IndexError:
	    	print("bad topic", msg.topic)

	def on_publish(self, client, obj, mid):
	    #print("mid: " + str(mid))
	    pass

	def on_subscribe(self, client, obj, mid, granted_qos):
	    print("Subscribed: " + str(mid) + " " + str(granted_qos))
	    

	def on_log(self, client, obj, level, string):
	    print(string)

	def start(self):
		try:
			self.loop_start()
			while True:
				self.publish(self._build_topic("heartbeat"), json.dumps({"status":"GOOD"}))
				time.sleep(5)
		except KeyboardInterrupt:
			self.loop_stop()

if __name__ == '__main__':
	if os.environ.get('PLATFORM', None) == 'rpi':
		mech = FeedMech()
	else:
		mech = FeedMechDummy()
	mech.home()
	feeder = Feeder(host="broker", port=1883, mech=mech)
	print("Starting up...")
	time.sleep(10)
	feeder.start()

