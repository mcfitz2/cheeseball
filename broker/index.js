var mosca = require("mosca");
//var ascoltatore = {
//    type: 'redis',
//    redis: require('redis'),
//    db: 12,
//    port: 6379,
//    return_buffers: true, // to handle binary payloads
//    host: "redis"
//};


var settings = {
    port: 1883,
//    backend: ascoltatore,
    logger: {
        name: "broker",
        level: 30,
    }
};

var server = new mosca.Server(settings);

server.on('ready', setup);
server.on('clientDisconnected', function(client) {
    server.publish("feeders/"+client.id+"/disconnect", "OK");
});

function setup() {
        server.authorizePublish = (client, topic, payload, callback) => {
            try {
                var auth = client.id == topic.split('/')[1] || client.id.indexOf("tester") == 0;
                callback(null, auth);
            } catch {
                callback(null, false);
            }
        }
        server.authorizeSubscribe = (client, topic, callback) => {
            try {
                var auth = client.id == topic.split('/')[1] || client.id.indexOf("tester") == 0;
                callback(null, auth);
            } catch {
                callback(null, false)
            }
        }
    console.log('Mosca server is up and running');
}
