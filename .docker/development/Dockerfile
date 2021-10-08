# FROM public.ecr.aws/ideacrew/enroll:base as enroll
FROM ruby:2.5.1 as enroll

LABEL author="IdeaCrew"

ARG NODE_MAJOR
ARG YARN_VERSION
ARG BUNDLER_VERSION_OVERRIDE

ENV HOME /enroll
RUN mkdir -p $HOME
WORKDIR $HOME

# NodeJS download/config
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

# Yarn download/config
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo 'deb http://dl.yarnpkg.com/debian/ stable main' >/etc/apt/sources.list.d/yarn.list

# Install required packages/libraries
RUN apt-get update \
  && apt-get -yq dist-upgrade \
  && apt-get install -y git gcc openssl libyaml-dev libyaml-cpp-dev libyaml-cpp0.5v5 libffi-dev \
    libffi6 libreadline-dev zlibc libgdbm-dev libncurses-dev autoconf fontconfig unzip zip \
    sshpass bzip2 libxrender1 libxext6 build-essential nodejs vim libsodium18 \
  && apt-get autoremove -y

ENV GEM_HOME="/usr/local/bundle"
# Configure bundler and PATH, install bundler version
ENV LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3 \
  BUNDLE_PATH=$GEM_HOME
ENV BUNDLE_BIN=$BUNDLE_PATH/bin

RUN mkdir -p $BUNDLE_PATH && mkdir -p $BUNDLE_BIN

ENV PATH $GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH

ENV BUNDLER_VERSION=$BUNDLER_VERSION_OVERRIDE
RUN gem install --source "https://rubygems.org" bundler --version $BUNDLER_VERSION

# Adding gems
COPY . $HOME
RUN cd $HOME && bundle install && bundle binstubs bundler
# RUN cd $HOME && yarn install --check-files

RUN unset BUNDLE_PATH
RUN unset BUNDLE_BIN
