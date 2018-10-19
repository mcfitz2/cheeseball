FROM  ruby:alpine


RUN apk update && apk add --virtual build-dependencies \
	build-base \
	gcc \
	wget \
	git


# Install gems
ENV APP_HOME /app
ENV HOME /root
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY Gemfile* $APP_HOME/
RUN bundle install

# Upload source
COPY . $APP_HOME

# Start server
ENV PORT 8000
EXPOSE 8000
CMD ["ruby", "index.rb"]

