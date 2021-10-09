# FROM public.ecr.aws/ideacrew/enroll:base as enroll
FROM ruby:2.5.1 as enroll

LABEL author="IdeaCrew"

# ARG NODE_MAJOR
# ARG YARN_VERSION
# ARG BUNDLER_VERSION_OVERRIDE

ENV HOME /enroll
RUN mkdir -p $HOME
WORKDIR $HOME

# NodeJS download/config
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

# Install required packages/libraries
RUN apt-get update \
  && apt-get -yq dist-upgrade \
  && apt-get install -y git gcc openssl libyaml-dev libyaml-cpp-dev libyaml-cpp0.5v5 libffi-dev \
    libffi6 libreadline-dev zlibc libgdbm-dev libncurses-dev autoconf fontconfig unzip zip \
    sshpass bzip2 libxrender1 libxext6 build-essential nodejs vim libsodium18 \
  && npm install --global yarn \
  && apt-get autoremove -y

ENV GEM_HOME="/usr/local/bundle"
# Configure bundler and PATH, install bundler version
ENV LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3 \
  BUNDLER_VERSION=2.2.29 \
  BUNDLE_PATH=$GEM_HOME
ENV BUNDLE_BIN=$BUNDLE_PATH/bin

RUN mkdir -p $BUNDLE_PATH && mkdir -p $BUNDLE_BIN

ENV PATH $GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH

# Adding gems
COPY . $HOME

# RUN gem install bundler -v "<2" -N
# && gem install --source "https://rubygems.org" bundler --version '1.16.6' \
# && gem install --source "https://rubygems.org" bundler --version '2.2.29' \
RUN cd $HOME \
  && gem install bundler \
  && bundle install \
  && bundle binstubs bundler

RUN cd $HOME && yarn install --check-files

RUN unset BUNDLE_PATH
RUN unset BUNDLE_BIN
