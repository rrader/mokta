FROM ruby:2.5.1

ENV APP_ROOT /app

WORKDIR $APP_ROOT

ADD Gemfile* ./
RUN gem install bundler && bundle install -j3 && bundle clean

COPY . ./

CMD ["ruby", "app.rb", "-o", "0.0.0.0", "-p", "4001"]
