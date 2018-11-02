const express = require("express")
const bodyParser = require('body-parser')
const request = require("request")
const mailgun = require("mailgun-js")
const app = express()

app.use(bodyParser.json())

const mailgun = require('mailgun-js')({apiKey: process.env.MAILGUN_API_KEY, domain: process.env.MAILGUN_DOMAIN});

app.post("/notifications/send/all", (req, res) => {
	return res.status(501).send()
});

app.post("/notifications/send/:user_id", (req, res) => {
	request.get({url:"http://user-service:8000/users/"+req.params.user_id, json:true}, (err, response, body) {
		let user = body
		let data = {
		  from: "no-reply@"+process.env.MAILGUN_DOMAIN,
		  to: user.email,
		  subject: req.body.subject,
		  text: req.body.message
		};

		mailgun.messages().send(data, function (error, body) {
			console.log(err, body)
			if (err) {
				res.status(500).json({error:err})
			} else {
				res.status(200).send()
			}
		});
	});
});



app.listen(8000)

