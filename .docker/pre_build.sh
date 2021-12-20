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

cat config/mongoid.yml