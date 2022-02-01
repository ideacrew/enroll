# setup docker image config
#cp Gemfile Gemfile.tmp
#cp Gemfile.lock Gemfile.lock.tmp
cp config/cable.yml config/cable.yml.tmp
cp config/mongoid.yml config/mongoid.yml.tmp
cp config/saml.yml config/saml.yml.tmp
#cp config/symmetric-encryption.yml config/symmetric-encryption.yml.tmp
cp config/environments/production.rb config/environments/production.rb.tmp
cp config/initializers/devise.rb config/initializers/devise.rb.tmp
cp config/initializers/redis.rb config/initializers/redis.rb.tmp
cp app/models/saml_information.rb app/models/saml_information.rb.tmp

#cp .docker/config/Gemfile .
#cp .docker/config/Gemfile.lock .
cp .docker/config/puma.rb config/
cp .docker/config/cable.yml config/
cp .docker/config/mongoid.yml config/
cp .docker/config/saml.yml config/
cp .docker/config/saml_information.rb app/models/
#cp .docker/config/symmetric-encryption.yml config/
cp .docker/config/production.rb config/environments/
cp .docker/config/devise.rb config/initializers/
cp .docker/config/redis.rb config/initializers/
cp .docker/config/sidekiq.rb config/initializers/

docker build --build-arg BUNDLER_VERSION_OVERRIDE='2.0.1' \
             --build-arg NODE_MAJOR='12' \
             --build-arg YARN_VERSION='1.22.4' \
             --build-arg ENROLL_DB_HOST='host.docker.internal' \
             --build-arg ENROLL_DB_PORT="27017" \
             --build-arg ENROLL_DB_NAME="enroll_production" \
             --build-arg REDIS_HOST_ENROLL="localhost" \
             --build-arg RABBITMQ_URL="amqp://rabbitmq:5672" \
	     --build-arg RABBITMQ_HOST="amqp://rabbitmq" \
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
docker push $2:$1

#mv Gemfile.tmp Gemfile
#mv Gemfile.lock.tmp Gemfile.lock
mv config/cable.yml.tmp config/cable.yml
mv config/mongoid.yml.tmp config/mongoid.yml
mv config/saml.yml.tmp config/saml.yml
mv app/models/saml_information.rb.tmp  app/models/saml_information.rb
#mv config/symmetric-encryption.yml.tmp config/symmetric-encryption.yml
mv config/environments/production.rb.tmp config/environments/production.rb
mv config/initializers/devise.rb.tmp config/initializers/devise.rb
mv config/initializers/redis.rb.tmp config/initializers/redis.rb
rm config/puma.rb
rm config/initializers/sidekiq.rb
