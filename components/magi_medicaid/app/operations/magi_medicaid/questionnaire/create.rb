# frozen_string_literal: true

module MagiMedicaid
  module Operations
    module Questionnaire
      # Create a Feature
      class Create
        send(:include, Dry::Monads[:result, :do, :try])

        def call(path:, registry:)
          file_io         = yield read(path)
          params          = yield deserialize(file_io)
          feature_hashes  = yield serialize(params)
          features        = yield create(feature_hashes)
          yield persist(features, registry)

          Success(features)
        end

        private

        def read(path)
          file_io = ResourceRegistry::Stores::File::Read.new.call(path)

          if file_io.success?
            Success(file_io.value!)
          else
            Failure("File read failed!!")
          end
        end

        # def deserialize(file_io)
        #   params = ResourceRegistry::Serializers::Yaml::Deserialize.new.call(file_io)
        #
        #   if params.success?
        #     Success(params.value!)
        #   else
        #     Failure("Yaml deserialize failied!!")
        #   end
        # end
        #
        # def serialize(params)
        #   feature_hashes = ResourceRegistry::Serializers::Features::Serialize.new.call(params)
        #
        #   if feature_hashes.success?
        #     Success(feature_hashes.value!)
        #   else
        #     Failure("Feature serialize failed!!")
        #   end
        # end
        #
        # def create(feature_hashes)
        #   Try do
        #     feature_hashes.collect do |feature_hash|
        #       result = ResourceRegistry::Operations::Features::Create.new.call(feature_hash)
        #       return result if result.failure?
        #       result.value!
        #     end
        #   end.to_result
        # end
        #
        # def persist(features, registry)
        #   features.each do |feature|
        #     ResourceRegistry::Stores.persist(feature, registry) if defined? Rails
        #     registry.register_feature(feature)
        #   end
        #
        #   Success(registry)
        # end
      end
    end
  end
end