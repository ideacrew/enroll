docker build --build-arg BUNDLER_VERSION_OVERRIDE='2.0.1' \
             --build-arg NODE_MAJOR='12' \
             --build-arg YARN_VERSION='1.22.4' \
             --build-arg ENROLL_DB_HOST='localhost' \
             --build-arg ENROLL_DB_PORT="27017" \
             --build-arg ENROLL_DB_NAME="enroll_production" \
             --build-arg REDIS_HOST_ENROLL="localhost" \
             --build-arg RABBITMQ_URL="amqp://localhost:5672" \
	     --build-arg RABBITMQ_HOST="amqp://localhost" \
	     --build-arg RABBITMQ_PORT="5672" \
	     --build-arg RABBITMQ_VHOST="event_source" \
	     --build-arg MITC_HOST="http://mitc" \
	     --build-arg MITC_PORT="3001" \
	     --build-arg MITC_URL="http://mitc:3001" \
             --build-arg RIDP_CLIENT_KEY_PATH="./config/fdsh.key" \
             --build-arg RIDP_INITIAL_SERVICE_URL="https://impl.hub.cms.gov/Imp1" \
             --build-arg RIDP_CLIENT_CERT_PATH="./config/fdsh.pem" \
             --build-arg RIDP_SERVICE_PASSWORD="password" \
             --build-arg RIDP_SERVICE_USERNAME="user" \
	     --build-arg CLIENT="me" \
             --build-arg SECRET_KEY_BASE="c8d2b9b204fbac78081a88a2c29b28cfeb82e6ccd3664b3948b813463b5917b315dbbd3040e8dffcb5b68df427099db0ce03e59e2432dfe5d272923b00755b82" \
             -f .docker/production/Dockerfile --target app -t $2:$1 --network="host" .


