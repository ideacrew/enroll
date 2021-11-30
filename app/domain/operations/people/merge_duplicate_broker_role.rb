# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    # This class uses merge broker with multiple person records
    class MergeDuplicateBrokerRole
      send(:include, Dry::Monads[:result, :do])
      send(:include, Dry::Monads[:try])

      # params {
      #     source_hbx_id:,
      #     target_hbx_id:
      #   }
      def call(params)
        broker_record = yield find_broker(params)
        consumer_record = yield find_consumer(params)
        _result = yield validate(broker_record, consumer_record)
        consumer_record = yield merge(broker_record, consumer_record)
        writing_agent = yield save_and_delete_broker_role(broker_record, consumer_record)

        yield update_broker_families(writing_agent, consumer_record)
        yield delete_broker_record(broker_record)

        Success(consumer_record)
      end

      private

      def find_broker(params)
        broker_record = Person.by_hbx_id(params[:source_hbx_id]).first

        if broker_record
          Success(broker_record)
        else
          Failure("Unable to find broker person record with hbx id #{params[:source_hbx_id]}")
        end        
      end

      def find_consumer(params)
        consumer_record = Person.by_hbx_id(params[:target_hbx_id]).first

        if consumer_record
          Success(consumer_record)
        else
          Failure("Unable to find broker person record with hbx id #{params[:target_hbx_id]}")
        end
      end

      def validate(broker_record, consumer_record)
        errors = []
        errors << ["Both consumer and person records are claimed"] if broker_record.user.present? && consumer_record.user.present?
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

      def merge(broker_record, consumer_record)
        Person.relations.each do |rel, rel_metadata| 
          next unless merge_map.key?(rel.to_sym)
          instruction = merge_map[rel.to_sym]
          if instruction[:attribute]
            unless consumer_record.send(instruction[:attribute])
              consumer_record.send("#{instruction[:attribute]}=", broker_record.send(instruction[:attribute]))
              p "Added #{rel} attribute for consumer record."
            end
            next
          end

          broker_value = broker_record.send(rel)
          if broker_value.present?
            consumer_value = consumer_record.send(rel)

            if rel.pluralize == rel && instruction[:on]
              broker_value.each do |embed_record|
                if consumer_value.none?{|r| r.send(instruction[:on]) == embed_record.send(instruction[:on])}
                  consumer_record.send_chain(rel, ["build",  broker_value.attributes])
                  p "Added #{rel} to consumer record with #{instruction[:on]} #{embed_record.send(instruction[:on])}."
                end
              end
            else
              unless consumer_value
                consumer_record.send("build_#{rel}", broker_value.attributes.merge('_id' => BSON::ObjectId.new))
                p "Added #{rel} to consumer record."
              end
            end
          end
        end

        # if consumer_record.save
          # p "Saved changes to consumer person record."
          Success(consumer_record)
        # else
        #   p "Failed to save consumer due to #{consumer_record.errors.to_h}."
        #   Failure(consumer_record.errors.to_h)
        # end
      end

      def save_and_delete_broker_role(broker_record, consumer_record)
        writing_agent = broker_record.broker_role
  
        if consumer_record.valid?
          broker_record.broker_role.delete
          consumer_record.save!
          Success(writing_agent)
        else
          Failure("Unable to save consumer record due to #{consumer_record.errors.to_h}")
        end
      end

      def update_broker_families(writing_agent, consumer_record)
        Family.by_writing_agent_id(writing_agent.id).each do |family|
          
          family.broker_agency_accounts.where(:writing_agent_id => writing_agent.id, :is_active => true).each do |baa|
            family.broker_agency_accounts << baa.class.new({
              start_on: baa.start_on,
              writing_agent_id: consumer_record.broker_role.id,
              benefit_sponsors_broker_agency_profile_id: baa.benefit_sponsors_broker_agency_profile_id,
              is_active: true
            })

            baa.update_attributes!(is_active: false, end_on: Date.today)
          end
          p "Created new broker agency account for family #{family.hbx_assigned_id}."
          family.save!
        end

        Success(true)
      end

      def delete_broker_record(broker_record)
        broker_record.delete
        p "Delete broker person record."

        Success(true)
      end
    end
  end
end