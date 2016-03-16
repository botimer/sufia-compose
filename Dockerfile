#FROM ruby:2.3
#FROM rails:onbuild
#FROM rails:4.2.5
#FROM sufia-base:4.2.5
FROM botimer/misc:sufia-base-425

ENV APP_HOME /usr/src/app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
    BUNDLE_JOBS=2 \
    BUNDLE_PATH=/bundle

RUN bundle install

ADD . $APP_HOME

CMD ["bin/rails", "console"]

