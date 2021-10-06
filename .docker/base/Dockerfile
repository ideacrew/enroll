########################
### app/rails config ###
########################

FROM ruby:2.5.1 AS app

LABEL author="IdeaCrew"

ARG NODE_MAJOR

RUN apt-get update && \
    apt-get -yq dist-upgrade && \
<<<<<<< HEAD
    apt-get install -y git gcc openssl libyaml-dev libyaml-cpp-dev libyaml-cpp0.5v5 libffi-dev libffi6 libreadline-dev libsodium-dev \
=======
    apt-get install -y git gcc openssl libyaml-dev libyaml-cpp-dev libyaml-cpp0.5v5 libffi-dev libffi6 libreadline-dev libsodium23 \
>>>>>>> 78e9547eb6 (add libsodium23 library)
                       zlibc libgdbm-dev libncurses-dev autoconf fontconfig unzip zip sshpass bzip2 libxrender1 libxext6 \
                       build-essential ca-certificates && \
    apt-get autoremove -y

# NodeJS download/config
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -x -
RUN apt-get install nodejs -y
RUN npm install --global yarn

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

# Adding gems
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN bundle install --jobs 20 --retry 5 --without development test 
