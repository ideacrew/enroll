docker build -f .docker/production/Dockerfile --target app -t $2:$1 --network="host" .
