FROM node:alpine

# Create app directory
RUN mkdir -p /app
WORKDIR /app

# --no-cache: download package index on-the-fly, no need to cleanup afterwards
# --virtual: bundle packages, remove whole bundle at once, when done
RUN apk --no-cache --virtual build-dependencies add \
    python \
    git \
    make \
    g++ 
# Install app dependencies
COPY package.json /app/
RUN npm install
# Bundle app source
COPY . /app
EXPOSE 1883
CMD ["npm", "start"]
