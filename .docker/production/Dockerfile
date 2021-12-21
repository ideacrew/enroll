########################
### app/rails config ###
########################

FROM public.ecr.aws/ideacrew/enroll:base  AS app

LABEL author="IdeaCrew"


# Configure bundler and PATH, install bundler version
ENV LANG=C.UTF-8 \
    GEM_HOME=/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH \
    BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH $BUNDLE_BIN:$GEM_HOME/gems/bin:$PATH

ARG BUNDLER_VERSION_OVERRIDE
ENV BUNDLER_VERSION=$BUNDLER_VERSION_OVERRIDE
RUN gem update --system && gem install bundler:$BUNDLER_VERSION

# Configure app home directory
ENV HOME /enroll
RUN mkdir -p $HOME
WORKDIR $HOME
COPY . $HOME

RUN yarn install

# Setting env up
ARG SECRET_KEY_BASE
ARG ENROLL_DB_HOST
ARG ENROLL_DB_PORT
ARG ENROLL_DB_NAME
ARG RABBITMQ_URL
ARG RABBITMQ_HOST
ARG RABBITMQ_PORT
ARG RABBITMQ_VHOST
ARG MITC_HOST
ARG MITC_PORT
ARG MITC_URL
ARG RIDP_CLIENT_KEY_PATH
ARG RIDP_INITIAL_SERVICE_URL
ARG RIDP_CLIENT_CERT_PATH
ARG RIDP_SERVICE_PASSWORD
ARG RIDP_SERVICE_USERNAME
ARG REDIS_HOST_ENROLL
ARG CLIENT
ENV RAILS_ENV='production'
ENV NODE_ENV='production'
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

# Adding gems
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN bundle install --jobs 20 --retry 5 --without development test
RUN bundle exec rake configuration:client_configuration_toggler client=$CLIENT
RUN bundle exec rake assets:precompile
RUN rm -f /enroll/config/master.key && rm -f /enroll/config/credentials.yml.enc

#CMD ["./entrypoints/docker-entrypoint.sh"]


########################
### web/nginx config ###
########################

FROM nginx:1.17.6-alpine as web

RUN mkdir /enroll

# copy assets from the app build and nginx config
COPY --from=app /enroll/public /enroll/
COPY .docker/production/nginx.conf /etc/nginx/conf.d/enroll.conf
RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf-bkp
