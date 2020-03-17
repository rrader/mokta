FROM citizensadvice/sinatra:1.0

ENV APP_ROOT /app

WORKDIR $APP_ROOT

ADD Gemfile* ./

RUN \
  apk update && apk upgrade && \
  apk --no-cache add \
    gcc \
    make \
    libc-dev

RUN gem update --system && \
    gem install bundler && \
    bundle install

COPY . ./

CMD ["ruby", "app.rb", "-o", "0.0.0.0", "-p", "4001"]
