FROM node:alpine


# --no-cache: download package index on-the-fly, no need to cleanup afterwards
# --virtual: bundle packages, remove whole bundle at once, when done
RUN apk --no-cache --virtual build-dependencies add \
    python \
    git \
    make \
    g++
RUN mkdir -p /app
COPY package.json /app/
RUN npm install

WORKDIR /app
COPY . /app

EXPOSE 8000
CMD [ "node", "index.js" ]
