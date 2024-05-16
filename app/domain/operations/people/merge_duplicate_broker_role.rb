# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    # This class uses merge broker with multiple person records
    class MergeDuplicateBrokerRole
      include Dry::Monads[:do, :result, :try]

      # params {
      #     source_hbx_id:,
      #     target_hbx_id:
      #   }
      def call(params)
        broker_record = yield find_broker(params)
        consumer_record = yield find_consumer(params)
        yield validate(broker_record, consumer_record)
        # yield validate_merge_map  # implement validation for the merge map passed in from outside
        consumer_record = yield merge(broker_record, consumer_record)
        _writing_agent = yield save_and_delete_broker_role(broker_record, consumer_record)

        # yield update_broker_assigned_families(writing_agent, consumer_record)
        yield delete_broker_record(broker_record)

        Success(consumer_record)
      end

      private

      def find_broker(params)
        broker_record = Person.by_hbx_id(params[:source_hbx_id]).first

        if broker_record&.broker_role
          Success(broker_record)
        else
          Failure("Unable to find person record with broker role for hbx id #{params[:source_hbx_id]}")
        end
      end

      def find_consumer(params)
        consumer_record = Person.by_hbx_id(params[:target_hbx_id]).first

        if consumer_record&.consumer_role
          Success(consumer_record)
        else
          Failure("Unable to find person record with consumer role for hbx id #{params[:target_hbx_id]}")
        end
      end

      def validate(broker_record, consumer_record)
        errors = []
        errors << "Both consumer and person records have user records" if broker_record.user.present? && consumer_record.user.present?
        errors << "SSN not present for consumer" unless consumer_record.ssn
        errors << "SSN present for broker record" if broker_record.ssn && consumer_record.ssn != broker_record.ssn
        errors << "Broker role already exists for consumer" if consumer_record.broker_role.present? || consumer_record.broker_agency_staff_roles.present?
        if errors.any?
          Failure(errors)
        else
          Success(true)
        end
      end

      def merge_map
        {
          user: {from: :source, attribute: :user_id},
          broker_role: {from: :source},
          broker_agency_staff_roles: {from: :source},
          addresses: {from: :source, on: :kind},
          phones: {from: :source, on: :kind},
          emails: {from: :source, on: :kind},
          documents: {from: :source}
        }
      end

      # TODO
      def validate_merge_map
        Success(merge_map)
      end

      def merge(broker_record, consumer_record)
        Person.relations.each do |rel, _rel_metadata|
          if merge_map.key?(rel.to_sym)
            merge_attributes(broker_record, consumer_record, rel)
            merge_embed_documents(broker_record, consumer_record, rel)
          end
        end

        Success(consumer_record)
      end

      def merge_attributes(broker_record, consumer_record, rel)
        instruction = merge_map[rel.to_sym]
        return unless instruction[:attribute]
        return if consumer_record.send(instruction[:attribute])
        consumer_record.send("#{instruction[:attribute]}=", broker_record.send(instruction[:attribute]))
        p "Added #{rel} attribute for consumer record."
      end

      def merge_embed_documents(broker_record, consumer_record, rel)
        instruction = merge_map[rel.to_sym]
        return if instruction[:attribute]

        broker_value = broker_record.send(rel)
        return unless broker_value.present?
        consumer_value = consumer_record.send(rel)

        if rel.pluralize == rel && instruction[:on]
          broker_value.each do |embed_record|
            if consumer_value.none?{|r| r.send(instruction[:on]) == embed_record.send(instruction[:on])}
              consumer_record.send(rel).build(embed_record.attributes)
              p "Added #{rel} to consumer record with #{instruction[:on]} #{embed_record.send(instruction[:on])}."
            end
          end
        else
          unless consumer_value
            consumer_record.send("build_#{rel}", broker_value.attributes)
            p "Added #{rel} to consumer record."
          end
        end
      end

      def save_and_delete_broker_role(broker_record, consumer_record)
        writing_agent = broker_record.broker_role

        if consumer_record.valid?
          broker_record.broker_role.delete
          if broker_record.user
            broker_record.user_id = nil
            broker_record.save(validate: false)
          end
          consumer_record.save!
          Success(writing_agent)
        else
          Failure("Unable to save consumer record due to #{consumer_record.errors.to_h}")
        end
      end

      def delete_broker_record(broker_record)
        broker_record.delete
        p "Delete broker person record."

        Success(true)
      end
    end
  end
end