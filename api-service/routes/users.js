const express = require('express')
const request = require("request")
const httpProxy = require('express-http-proxy')
const userServiceProxy = httpProxy('http://user-service:8000')
const passport = require("passport")

module.exports = function(app) {

app.post("/authenticate", (req, res) => {
	return userServiceProxy(req, res)
})


app.get("/users", passport.authenticate('jwt', { session: false }), (req, res) => {
	return userServiceProxy(req, res)
})
app.post("/users", passport.authenticate('jwt', { session: false }), (req, res) => {
	return userServiceProxy(req, res)
})
app.get("/users/:user_id", passport.authenticate('jwt', { session: false }), (req, res) => {
	return userServiceProxy(req, res)
})
app.patch("/users/:user_id", passport.authenticate('jwt', { session: false }), (req, res) => {
	return userServiceProxy(req, res)
})
app.delete("/users/:user_id", passport.authenticate('jwt', { session: false }), (req, res) => {
	return userServiceProxy(req, res)
})
app.post("/users/:user_id/password", passport.authenticate('jwt', { session: false }), (req, res) => {
	return userServiceProxy(req, res)
})
}
