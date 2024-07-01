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
        Success(publish_result)
      end

      private

      def validate(headers, params)
        Rails.logger.info { params }
        return Failure('Missing after save version') if params[:after_save_version].blank?
        Success(params)
      end

      def construct_and_publish_cv_family_events(headers, person, values)
        person.families.each do |family|
          payload = construct_before_and_after_cv3_family(family, headers, person, values)
          return payload if payload.failure?
          event('events.families.created_or_updated', attributes: payload.success, headers: headers)&.success&.publish
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
          before_family_member = before_save_cv3_family[:family_members].detect do |family_member|
            family_member[:person][:hbx_id] == values[:after_save_version][:hbx_id]
           end
           
           before_person_saved = ::Operations::CreateBeforePersonSaved.new.call(values[:changed_attributes], before_family_member)
           if before_person_saved.success?
              return Success({before_save_cv3_family: before_save_cv3_family, after_save_cv3_family: cv3_family.success})
           else
            Rails.logger.info { "Before Save CV3 Family failed for family: #{values[:after_save_version][:hbx_id]} #{before_save.failure} #{}"}
            return Success({before_save_cv3_family: {}, after_save_cv3_family: cv3_family.success})
           end                
        else
          Rails.logger.error { "Failed to construct cv3 family for family with hbx id: #{values[:after_save_version][:hbx_id]} due to #{cv3_family.failure}" }
          return Failure("Failed to construct cv3 family for family with hbx id: #{values[:after_save_version][:hbx_id]} due to #{cv3_family.failure}")
        end
      rescue StandardError => e
        Rails.logger.error {"Error constructing cv3 family for family with hbx id: #{values[:after_save_version][:hbx_id]} due to: #{e.message}, backtrace: #{e.backtrace.join("\n")}"}
        Failure("Error constructing cv3 family for family with hbx id: #{values[:after_save_version][:hbx_id]} due to: #{e.message}, backtrace: #{e.backtrace.join("\n")}" )
      end

      def find_person(after_save_version)
        ::Operations::People::Find.new.call({ person_hbx_id: after_save_version[:hbx_id] })
      end

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
        Rails.logger.error { "Unable to generate events.person_saved event due to error: #{e.message}, backtrace: #{e.backtrace.join("\n")}" }
        Success("Unable to generate events.person_saved event due to error: #{e.message}, backtrace: #{e.backtrace.join("\n")}")
      end
    end
  end
end
