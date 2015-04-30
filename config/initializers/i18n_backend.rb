require 'mongo_i18n'
I18n.backend = I18n::Backend::Chain.new(I18n::Backend::KeyValue.new(MongoI18n.store), I18n.backend)
