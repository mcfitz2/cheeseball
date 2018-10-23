FROM python:3-alpine

WORKDIR /usr/src/app
RUN apk add --update alpine-sdk

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD [ "python", "-u", "./index.py" ]
