# frozen_string_literal: true

module Operations
  module Private
    # This class is to publish before and after save cv3 family payloads
    class PersonSaved
      include Dry::Monads[:result, :do]
      include EventSource::Command

      # 1. Publish CV3 Person to support existing functionality DONE
      # 2. Publish Before and After Save CV3 Family
     
      def call(headers:, params:)
        values           = yield validate(headers, params)
        person           = yield find_person(values[:after_save_version])
        _result          = yield publish_person_saved_event(person)

        publish_result   = yield construct_and_publish_cv_family_events(headers, person, values)

        # cv3_families     = yield construct_cv3_family(values[:after_save_version])
        # before_person    = yield construct_before_person(cv3_families, values[:changed_attributes], values[:after_save_version])
        # payload          = yield construct_publish_payload(values[:family], values[:family_member_id], before_person)
        # publish_payload(payload, headers)
        Success()
      end

      private

      # Here we might want to return a Failure monad if there are no changes.
      def construct_and_publish_cv_family_events(headers, person, values)
        return Failure('No changed attributes') if values[:changed_attributes].blank?
        person.families.each do |family|
          payload = construct_before_and_after_cv3_family(family, headers, person, values)
           # event('events.families.created_or_updated', attributes: payload, headers: headers).success.publish
        end
      end

      # 1. Here we need to construct each CvFamily Transform.
      # 2. Make 2 versions of the CvFamily.
      #   1. The newly constructed cv_family is the after_save_version.
      #   2. We need to make a copy of the cv_family and update the hash with the before_save person version.
      # 3. Publish events for each family with proper headers and attributes.
     
      def construct_before_and_after_cv3_family(family, headers, person, values)
        cv3_family = ::Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
        if cv3_family.success?
          before_save_cv3_family = cv3_family.success.deep_dup
          # merge values[:changed_attributes]
          before_family_member = before_save_cv3_family[:family_members].detect do |family_member|
            family_member[:person][:hbx_id] == values[:after_save_version][:hbx_id]
           end
           
           before_person_saved = ::Operations::BeforePersonSaved.new.call(values[:changed_attributes], before_family_member)
          #  binding.irb
           if before_person_saved.success?
            # Rails.logger.info { "Before Save CV3 Family Constructed #{before_save_cv3_family}"}
              return {before_save_cv3_family: before_save_cv3_family, after_save_cv3_family: cv3_family.success}
           else
            Rails.logger.info { "Before Save CV3 Family failed for family: #{values[:after_save_version][:hbx_id]} #{before_save.failure} #{}"}
            return Failure("Failed to construct before save cv3 family for family with hbx id: #{values[:after_save_version][:hbx_id]}")
           end                
        else
          Failure("Failed to construct cv3 family for family with hbx id: #{values[:after_save_version][:hbx_id]}")
        end
      end



      # def construct_cv3_family(after_save_version)

      #   person = Person.where(hbx_id: after_save_version[:hbx_id]).first

      #   return Failure('Person not found') if person.blank?

      #   family = person.primary_family
      #   Operations::Transformers::FamilyTo::Cv3Family.new.call(family, true)
      #   #! if they are part of more than one family, are we publishing twice?
      #   families = person.families.collect do |family|
      #     Operations::Transformers::FamilyTo::Cv3Family.new.call(family, true)

      #   end
      # end

      # def construct_before_person(cv3_families, changed_attributes, after_save_version)
      #   # binding.irb
      #   # construct cv3 family, find family member by hbx id and update the family member with the changed attributes
      #   # Do we loop through the changed attributes
      #   # find_family
      #   cv3_families.each do |cv3_family|
         
      #     return Failure('Person not found') if person.blank?
      #     person.merge!(changed_attributes)
      #     Success("Before Person Constructed")
      #   end
      # end


      def find_person(after_save_version)
        ::Operations::People::Find.new.call({ person_hbx_id: after_save_version[:hbx_id] })
      end

      # Any failure caused here should not impact the next steps.
      # For the same reason we will always return a Success.
      def publish_person_saved_event(person)
        cv_person = ::Operations::Transformers::PersonTo::Cv3Person.new.call(person)

        msg = if cv_person.success?
          event = event('events.person_saved', attributes: { gid: person.to_global_id.uri, payload: cv_person.success })
          if event.success?
            event.success.publish
            "Successfully published 'events.person_saved' for person with hbx_id: #{person.hbx_id}"
          else
            Rails.logger.error { "Event 'event.person_saved' failed to publish" }
            "Event 'event.person_saved' failed to publish"
          end
        else
          cv_person.failure
        end

        Success(msg)
      rescue StandardError => e
        Rails.logger.error { "Unable to generate events.person_saved event due to error: #{e}, backtrace: #{e.backtrace}" }
        Success("Unable to generate events.person_saved event due to error: #{e}, backtrace: #{e.backtrace}")
      end

      def validate(headers, params)
        Rails.logger.info {"1277 #{params[:changed_attributes].inspect}"}
        # return Failure('Missing before and after updated at') if headers.blank?
        return Failure('Missing after save version') if params[:after_save_version].blank?
        # return Failure('No Changed Attributes') if params[:changed_attributes].blank?

        Success(params)
      end
    end
  end
end
