FROM ruby:2.7.2-alpine3.12

ENV APP_ROOT /app
ENV LANG C.UTF-8

WORKDIR $APP_ROOT

RUN \
  apk update && apk upgrade && \
  apk --no-cache add \
    gcc \
    make \
    libc-dev

ADD Gemfile* ./

RUN \
  gem update --system && \
  gem install bundler && \
  bundle install

COPY . ./

CMD ["ruby", "app.rb", "-o", "0.0.0.0", "-p", "4001"]
