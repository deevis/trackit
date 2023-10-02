FROM ruby:3.1.2-slim


# BUILDING  ( run from bin/build_docker_arm64.bat) (or .sh)
# (new way) 
# docker buildx build -f production.Dockerfile --platform linux/arm64 -t forecast_checker-arm64 .
# docker image tag forecast_checker-arm64:latest 192.168.1.199:5000/deevis/forecast_checker-arm64:latest
# docker image push 192.168.1.199:5000/deevis/forecast_checker-arm64:latest
# 
# In your docker engine configuration, add this to prevent: server gave HTTP response to HTTPS client
#    "insecure-registries": ["192.168.1.199/8"]
#


# DEPLOYING
#
# You'll need to set these ENV vars
#   RAILS_ENV RAILS_SERVE_STATIC_FILES DB_HOST DB_SCHEMA DB_USERNAME DB_PASSWORD
# 
RUN apt-get update -qq && apt-get install -yq --no-install-recommends gnupg2 build-essential libpq-dev curl
RUN apt remove cmdtest

RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
    nodejs \
    yarn \
    default-libmysqlclient-dev \
    imagemagick \
    less \
    vim \
    dnsutils \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3 \
  RAILS_ENV=production

RUN gem update --system && gem install bundler

WORKDIR /usr/src/app

COPY Gemfile* ./

RUN bundle config frozen true \
 && bundle config jobs 4 \
 && bundle config deployment true \
 && bundle config without 'development test' \
 && bundle install

COPY . .

# Precompile assets
# SECRET_KEY_BASE or RAILS_MASTER_KEY is required in production, but we don't
# want real secrets in the image or image history. The real secret is passed in
# at run time
ARG SECRET_KEY_BASE=fakekeyforassets
RUN npm ci \
 && yarn build \
 && yarn build:css

RUN bundle exec rails assets:clobber assets:precompile

RUN mkdir -p tmp/pids

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]