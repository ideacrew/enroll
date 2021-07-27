docker build --build-arg BUNDLER_VERSION_OVERRIDE='2.0.1' \
             --build-arg NODE_MAJOR='10' \
             --build-arg YARN_VERSION='1.22.4' \
             -f .docker/development/Dockerfile --target app -t $1:$2 .
