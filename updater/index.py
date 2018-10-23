import docker

client = docker.from_env()

container = client.containers.get("feeder")
print(container.image.tags[0])
client.images.pull(container.image.tags[0])
new_container = client.containers.create(container.image.tags[0])
container.stop()
new_container.start()