# frozen_string_literal: true

module Operations
  module Private
    # This class publishes a cv3 family payload on family member created events
      class FamilyMemberCreated
        include Dry::Transaction
        include EventSource::Command
        
        def call(family_member)

          values = yield validate(family_member)
          build_and_publish_cv3_family(values)
        end

        Private
        
        def validate(family_member)
          return Failure if family_member.nil?
          Success(family_member)
        end

        def build_and_publish_cv3_family(family_member)
          headers = {updated_at: family_member.updated_at}
          family = family_member.family
          
          if family.present?
            cv3_family = build_cv3_family(family)
            if cv3_family.success?
              event('events.families.created_or_updated', attributes: {after_save_version: cv3_family.success}, headers: headers)&.success&.publish
              Rails.logger.info { "Successfully published 'events.families.created_or_updated' for family member with hbx_id: #{family_member&.person&.hbx_id}" }
              return Success(family_member)
            else
              return Failure("Failed to build cv3 family for family member: #{family_member&.person&.hbx_id} due to #{cv3_family.failure}")
            end
          else
            return Failure("Family not found for family member: #{family_member.person.hbx_id}")
          end
          
        end

        def build_cv3_family(family)
          Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
        end
      end
  end
  