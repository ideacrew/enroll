FROM public.ecr.aws/ideacrew/enroll:base as app

LABEL author="IdeaCrew"

ARG NODE_MAJOR

# NodeJS download/config
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

# Yarn download/config
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list

ARG YARN_VERSION
# Install required packages/libraries
RUN apt-get update && \
    apt-get -yq dist-upgrade && \
    apt-get install -y git gcc openssl libyaml-dev libyaml-cpp-dev libyaml-cpp0.5v5 libffi-dev libffi6 libreadline-dev \ 
                       zlibc libgdbm-dev libncurses-dev autoconf fontconfig unzip zip sshpass bzip2 libxrender1 libxext6 \ 
                       build-essential nodejs yarn=$YARN_VERSION-1 && \
    apt-get autoremove -y 

# Configure bundler and PATH, install bundler version
ENV LANG=C.UTF-8 \
    GEM_HOME=/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH \
    BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH /enroll/bin:$BUNDLE_BIN:$PATH

ARG BUNDLER_VERSION_OVERRIDE
ENV BUNDLER_VERSION=$BUNDLER_VERSION_OVERRIDE
RUN gem update --system && gem install bundler:$BUNDLER_VERSION

# Configure app home directory
ENV HOME /enroll
RUN mkdir -p $HOME
WORKDIR $HOME

# Setting env up
ENV RAILS_ENV='development'
ENV NODE_ENV='development'

# Adding gems
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
COPY . $HOME
RUN bundle install && \
    yarn install --check-files 
