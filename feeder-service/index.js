const mqtt = require("mqtt")
const express = require("express")
const mqtt_router = require("mqtt-route")
const MongoClient = require('mongodb').MongoClient;
const bodyParser = require('body-parser')
const cron = require('node-cron');



MongoClient.connect(process.env.MONGO_URL, function(err, client) {
	const db = client.db("feeders");
	const feeder_col = db.collection("feeders")
	const tasks = [{
			name:"update_offline_status",
			schedule:"* * * * *",
			func: function {feeder_col.update({lastSeen:{$lte:new Date(new Date().getTime()-30000)}}, {$set:{status:"offline", status_description:"Feeder appears to be disconnected or powered off"}})}
		}
	]
	tasks.forEach((task) => {
		cron.schedule(task.schedule, () => {
			console.log("Running task: ", task.name)
			return task.func()
		})
	})

	function on_heartbeat(topic, message) {
		let feeder_uid = topic.split("/")[1]
		console.log("Got heartbeat from feeder", feeder_uid)
		feeder_col.findOneAndUpdate({uid: feeder_uid}, {$set: {lastSeen: new Date()}}, {upsert: true}, function(err,doc) {
			if (err) {
				console.log("error updating lastSeen for ", feeder_uid)
			}
		})
	}
        function on_feeding(topic, message) {
		let feeder_uid = topic.split("/")[1]
		feeder_col.findOneAndUpdate({uid: feeder_uid}, {$set: {status:"online", status_description:"", lastFeeding: new Date()}}, {upsert: false}, function(err,doc) {
			if (err) {
				console.log("error updating lastFeeding for ", feeder_uid)
			}
		})
	}
	var client  = mqtt.connect('mqtt://broker', {clientId:'feeder-service'})
	var router = new mqtt_router(client)

	router.route("feeders/+/heartbeat", on_heartbeat)
        router.route("feeders/+/feeding_complete", on_feeding)
	client.on('connect', function () {
	  router.init()
	})


	const app = express()
	app.use(bodyParser.json())

	app.post("/:feeder_uid/feed", (req, res) => {
		let cups = req.body.cups
		client.publish("feeders/"+req.params.feeder_uid+"/feed_requested", JSON.stringify({cups:cups}))
		setTimeout(() => {
			let checkTime = new Date(new Date().getTime() - 10000);
			feeder_col.findOne({uid:req.params.feeder_uid}, (err, feeder) => {
				if ("lastFeeding" in feeder && (feeder.lastFeeding >= checkTime)) {
					return res.status(200).send()
				} else {
					feeder_col.findOneAndUpdate({uid:req.params.feeder_uid}, {$set:{status:"error", "status_description":"Feeder did not respond to last feed request"}, {upsert:false}, (err, doc) => { 
						return res.status(500).json({"error":"Feeder did not  respond to feed request. Feeding may or may not have occurred."})
					});
				}
			})
		}, 10000)
	})

	app.post("/:feeder_uid/snapshot", (req, res) => {
		return res.status(501).send()
	})

	app.get("/", (req, res) => {
		feeder_col.find({}).toArray((err, feeders) => {
			if (err) {
				return res.status(500).send()
			} else {
				return res.json(feeders)
			}
		});
	})

	app.post("/", (req, res) => {
		//create new feeder
		return res.status(501).send()
	});

	app.get("/:feeder_uid", (req, res) => {
		feeder_col.findOne({uid:req.params.feeder_uid}, (err, feeder) => {
			if (err) {
				return res.status(500).send()
			} else {
				return res.json(feeder)
			}
		});
	})

	app.patch("/:feeder_uid", (req, res) =>{
		//update feeder
	})

	app.delete("/:feeder_uid", (req, res) => {
		feeder.deleteOne({uid:req.params.feeder_uid}, (err) => {
			if (err) {
				return res.status(500).send()
			} else {
				return res.status(200).send()
			}
		})
	})
	app.listen(8000)
});

