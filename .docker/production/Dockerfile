########################
### app/rails config ###
########################

# FROM public.ecr.aws/ideacrew/enroll:base  AS app

# LABEL author="IdeaCrew"


# Configure bundler and PATH, install bundler version
ENV LANG=C.UTF-8 \
    GEM_HOME=/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH \
    BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH $BUNDLE_BIN:$GEM_HOME/gems/bin:$PATH

ARG BUNDLER_VERSION_OVERRIDE=2.2.27
ENV BUNDLER_VERSION=$BUNDLER_VERSION_OVERRIDE
RUN gem update --system && gem install bundler:$BUNDLER_VERSION

# Configure app home directory
ENV HOME /enroll
RUN mkdir -p $HOME
WORKDIR $HOME
COPY . $HOME



# RUN yarn install

# Setting env up
ARG SECRET_KEY_BASE=c8d2b9b204fbac78081a88a2c29b28cfeb82e6ccd3664b3948b813463b5917b315dbbd3040e8dffcb5b68df427099db0ce03e59e2432dfe5d272923b00755b82
ARG ENROLL_DB_HOST=172.17.0.1
ARG ENROLL_DB_PORT=27017
ARG ENROLL_DB_NAME=enroll_production
ARG RABBITMQ_URL=amqp://rabbitmq:5672
ARG RABBITMQ_HOST=amqp://rabbitmq
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

ENV RAILS_ENV=production
ENV NODE_ENV=production
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

COPY config/mongoid.yml $HOME/config/mongoid.yml.tmp
COPY .docker/config/mongoid.yml $HOME/config/mongoid.yml

RUN cat config/mongoid.yml

# Adding gems
# COPY Gemfile Gemfile
# COPY Gemfile.lock Gemfile.lock

# RUN bundle install --jobs 20 --retry 5 --without development test 
# RUN bundle exec rake configuration:client_configuration_toggler client=$CLIENT
# RUN bundle exec rake assets:precompile 
# RUN rm -f /enroll/config/master.key && rm -f /enroll/config/credentials.yml.enc

#CMD ["./entrypoints/docker-entrypoint.sh"]


########################
### web/nginx config ###
######################## 

# FROM nginx:1.17.6-alpine as web

# RUN mkdir /enroll

# copy assets from the app build and nginx config
# COPY --from=app /enroll/public /enroll/
# COPY .docker/production/nginx.conf /etc/nginx/conf.d/enroll.conf
# RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf-bkp
