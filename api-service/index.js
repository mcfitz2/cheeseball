const express = require("express")
const passport = require("passport")
const request = require("request")
const JwtStrategy = require('passport-jwt').Strategy
const ExtractJwt = require('passport-jwt').ExtractJwt
const bodyParser = require("body-parser")
const morgan = require('morgan')

const opts = {
	jwtFromRequest:ExtractJwt.fromAuthHeaderAsBearerToken(),
	secretOrKey:process.env['JWT_SECRET'],
	issuer:process.env['JWT_ISSUER'],
}

const app = express()
app.use(morgan('combined'))
app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())

passport.use(new JwtStrategy(opts, function(jwt_payload, done) {
	console.log(jwt_payload)
	return done(err, false)
}));




// load routes
let normalizedPath = require("path").join(__dirname, "routes")
require("fs").readdirSync(normalizedPath).forEach(function(file) {
	console.log(normalizedPath, file)  
require(normalizedPath+"/"+file)(app)
});


app.listen(8000)
