############################################
### Base image ###
############################################

ARG RUBY_VERSION=2.5.1
FROM ruby:$RUBY_VERSION-slim-stretch as base
LABEL author="IdeaCrew"

ARG DEBIAN_FRONTEND=noninteractive
ARG BUNDLER_VERSION=2.2.27

# Must be set as ENV variable to overrride the default
ENV BUNDLER_VERSION=$BUNDLER_VERSION

RUN apt-get update && \
    apt-get -yq dist-upgrade && \
    apt-get install -y git gcc openssl libyaml-dev libyaml-cpp-dev libyaml-cpp0.5v5 libffi-dev libffi6 libreadline-dev libsodium-dev \
                       zlibc libgdbm-dev libncurses-dev autoconf fontconfig unzip zip sshpass bzip2 libxrender1 libxext6 \
                       build-essential ca-certificates && \
    apt-get autoremove -y

# Configure bundler and PATH, install bundler version
ENV GEM_HOME=/usr/local/bundle
ENV BUNDLE_PATH=$GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH
ENV BUNDLE_BIN=/usr/local/bin
ENV BUNDLE_JOBS=4
ENV BUNDLE_RETRY=3

ENV LANG=C.UTF-8

ENV PATH=$HOME/bin:$BUNDLE_BIN:$GEM_HOME/gems/bin:$PATH

RUN gem update --system
RUN rm -f /usr/local/bin/ruby/gems/*/specifications/default/bundler-*.gemspec
RUN gem install bundler -v $BUNDLER_VERSION

RUN groupadd --gid 1001 nonroot \
  && useradd --uid 1001 --gid nonroot --shell /bin/bash --create-home nonroot

ENV HOME=/enroll
RUN mkdir $HOME \
  && chown -R nonroot:nonroot $HOME

# Configure app home directory
WORKDIR $HOME

################################################################################
### Builder. Adds node and Yarn. Not necessary in production. ###
###############################################################################
FROM base as builder

ARG NODE_MAJOR=12
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq \
  && apt-get install -yq --no-install-recommends \
  build-essential \
  curl \
  libpq-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

# Add NodeJS to sources list
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

# Add Yarn to the sources list
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Install Nodejs & Yarn
RUN apt-get update -qq \
  && apt-get install -yq --no-install-recommends \
  nodejs \
  yarn \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

########################################################
# Node and Bundle for production
########################################################
FROM builder as prod_gems_and_assets

# Need all gemfiles and lockfiles
COPY --chown=nonroot:nonroot ./Gemfile $HOME/Gemfile
COPY --chown=nonroot:nonroot ./Gemfile.lock $HOME/Gemfile.lock
COPY --chown=nonroot:nonroot ./components $HOME/components
COPY --chown=nonroot:nonroot ./project_gems $HOME/project_gems

COPY --chown=nonroot:nonroot package.json $HOME/
COPY --chown=nonroot:nonroot yarn.lock $HOME/

ENV RAILS_ENV=production
ENV NODE_ENV=production

RUN apt-get update -qq \
  && apt-get install -yq --no-install-recommends \
  shared-mime-info \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

RUN bundle config set --local without 'development test' \
  && bundle install

RUN yarn install \
  && (rm -rf /tmp/* || true)

COPY --chown=nonroot:nonroot . $HOME

ARG SECRET_KEY_BASE=c8d2b9b204fbac78081a88a2c29b28cfeb82e6ccd3664b3948b813463b5917b315dbbd3040e8dffcb5b68df427099db0ce03e59e2432dfe5d272923b00755b82

# Used in multiple places, easier than passing in multiple
# build-args and overriding each one of them, needs to be
# localhost in GitHub Actions, i.e. HOST_STRING=localhost
ARG HOST_STRING=host.docker.internal

ARG ENROLL_DB_HOST=$HOST_STRING
ARG ENROLL_DB_PORT=27017
ARG ENROLL_DB_NAME=enroll_production
ARG RABBITMQ_URL=amqp://$HOST_STRING:5672
ARG RABBITMQ_HOST=amqp://$HOST_STRING
ARG RABBITMQ_PORT=5672
ARG RABBITMQ_VHOST=event_source
ARG MITC_HOST=http://mitc
ARG MITC_PORT=3001
ARG MITC_URL=http://mitc:3001
ARG RIDP_CLIENT_KEY_PATH=./config/fdsh.key
ARG RIDP_INITIAL_SERVICE_URL=https://impl.hub.cms.gov/Imp1
ARG RIDP_CLIENT_CERT_PATH=./config/fdsh.pem
ARG RIDP_SERVICE_PASSWORD=password
ARG RIDP_SERVICE_USERNAME=user
ARG REDIS_HOST_ENROLL=localhost
ARG CLIENT=me

ENV ENROLL_DB_HOST=$ENROLL_DB_HOST
ENV ENROLL_DB_PORT=$ENROLL_DB_PORT
ENV ENROLL_DB_NAME=$ENROLL_DB_NAME
ENV RABBITMQ_URL=$RABBITMQ_URL
ENV RABBITMQ_HOST=$RABBITMQ_HOST
ENV RABBITMQ_PORT=$RABBITMQ_PORT
ENV RABBITMQ_VHOST=$RABBITMQ_VHOST
ENV MITC_HOST=$MITC_HOST
ENV MITC_PORT=$MITC_PORT
ENV MITC_URL=$MITC_URL
ENV RIDP_CLIENT_KEY_PATH=$RIDP_CLIENT_KEY_PATH
ENV RIDP_INITIAL_SERVICE_URL=$RIDP_INITIAL_SERVICE_URL
ENV RIDP_CLIENT_CERT_PATH=$RIDP_CLIENT_CERT_PATH
ENV RIDP_SERVICE_PASSWORD=$RIDP_SERVICE_PASSWORD
ENV RIDP_SERVICE_USERNAME=$RIDP_SERVICE_USERNAME
ENV SECRET_KEY_BASE=$SECRET_KEY_BASE
ENV REDIS_HOST_ENROLL=$REDIS_HOST_ENROLL
ENV CLIENT=$CLIENT

COPY --chown=nonroot:nonroot ./.docker/config/mongoid.yml $HOME/config

RUN bundle exec rake configuration:client_configuration_toggler client=$CLIENT
RUN bundle exec rails assets:precompile \
  && yarn cache clean \
  && (rm -rf /tmp/* || true) \
  # Cleanup
  && rm -rf $BUNDLE_PATH/*.gem \
  && find $BUNDLE_PATH/ruby -name "*.c" -delete \
  && find $BUNDLE_PATH/ruby -name "*.o" -delete \
  && find $BUNDLE_PATH/ruby -name ".git"  -type d -prune -execdir rm -rf {} +

# https://github.com/rubygems/rubygems/issues/3225
RUN rm -rf /usr/local/bundle/ruby/*/cache

################################################################
# Deployable image
################################################################

FROM base as deploy

# Copy prebuilt gems
COPY --chown=nonroot:nonroot --from=prod_gems_and_assets $BUNDLE_PATH $BUNDLE_PATH

# Copy all app code again (sans gems, node_modules, assets)
COPY --chown=nonroot:nonroot . $HOME

# Copy prebuilt assets
COPY --chown=nonroot:nonroot --from=prod_gems_and_assets $HOME/public $HOME/public

# Copy ME-specific files
COPY --chown=nonroot:nonroot --from=prod_gems_and_assets $HOME/config/settings.yml $HOME/config/settings.yml
COPY --chown=nonroot:nonroot --from=prod_gems_and_assets $HOME/app/assets/images/logo/carrier/community_health_options.jpg $HOME/app/assets/images/logo/carrier/community_health_options.jpg
COPY --chown=nonroot:nonroot --from=prod_gems_and_assets $HOME/app/assets/stylesheets/ui-components/benefit-applications.scss $HOME/app/assets/stylesheets/ui-components/benefit-applications.scss
COPY --chown=nonroot:nonroot --from=prod_gems_and_assets $HOME/app/assets/stylesheets/ui-components/cards.scss $HOME/app/assets/stylesheets/ui-components/cards.scss
COPY --chown=nonroot:nonroot --from=prod_gems_and_assets $HOME/app/assets/stylesheets/ui-components/jquery-ui.scss.erb $HOME/app/assets/stylesheets/ui-components/jquery-ui.scss.erb
COPY --chown=nonroot:nonroot --from=prod_gems_and_assets $HOME/system/config/templates/features $HOME/system/config/templates/features

# Copy environment-based config files
COPY --chown=nonroot:nonroot ./.docker/config/mongoid.yml $HOME/config
COPY --chown=nonroot:nonroot ./.docker/config/puma.rb $HOME/config
COPY --chown=nonroot:nonroot ./.docker/config/cable.yml $HOME/config
COPY --chown=nonroot:nonroot ./.docker/config/mongoid.yml $HOME/config
COPY --chown=nonroot:nonroot ./.docker/config/saml.yml $HOME/config
COPY --chown=nonroot:nonroot ./.docker/config/saml_information.rb $HOME/app/models
COPY --chown=nonroot:nonroot ./.docker/config/production.rb $HOME/config/environments
COPY --chown=nonroot:nonroot ./.docker/config/devise.rb $HOME/config/initializers
COPY --chown=nonroot:nonroot ./.docker/config/redis.rb $HOME/config/initializers
COPY --chown=nonroot:nonroot ./.docker/config/sidekiq.rb $HOME/config/initializers

USER nonroot

ENV RAILS_ENV=production
ENV NODE_ENV=production

# ########################
# ### web/nginx config ###
# ########################

# FROM nginx:1.17.6-alpine as web

# RUN mkdir /enroll
# RUN rm -f /enroll/config/master.key && rm -f /enroll/config/credentials.yml.enc

# # copy assets from the app build and nginx config
# COPY --from=app /enroll/public /enroll/
# COPY .docker/production/nginx.conf /etc/nginx/conf.d/enroll.conf
# RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf-bkp
