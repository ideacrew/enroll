# frozen_string_literal: true

module Operations
  module Private
    # This class publishes before and after save cv family payloads
    class PersonSaved
      include Dry::Monads[:result, :do]
      include EventSource::Command

      def call(headers:, params:)
        values           = yield validate(headers, params)
        person           = yield find_person(values[:after_save_version])
        _result          = yield publish_person_saved_event(person)

        publish_result   = yield construct_and_publish_cv_family_events(headers, person, values)
        Success(publish_result)
      end

      private

      def validate(headers, params)
        return Failure('Missing headers') if headers.blank?
        return Failure('Missing after save version') if params[:after_save_version].blank?
        Success(params)
      end

      def construct_and_publish_cv_family_events(headers, person, values)
        person.families.each do |family|
          payload = construct_before_and_after_cv_family(family, headers, person, values)
          return payload if payload.failure?
          event('events.families.created_or_updated', attributes: payload.success, headers: headers)&.success&.publish
          Rails.logger.info { "Successfully published 'events.families.created_or_updated' for person with hbx_id: #{person&.hbx_id}" }
        end
        Success("Successfully published 'events.families.created_or_updated' for person with hbx_id: #{person.hbx_id}")
      end

      def construct_before_and_after_cv_family(family, _headers, _person, values)
        cv_family = ::Operations::Transformers::FamilyTo::Cv3Family.new.call(family, true)
        if cv_family.success?
          before_save_cv_family = cv_family.success.deep_dup
          before_family_member = before_save_cv_family[:family_members].detect do |family_member|
            family_member[:person][:hbx_id] == values[:after_save_version][:hbx_id]
          end

          before_person_saved = ::Operations::CreateBeforePersonSaved.new.call(values[:changed_attributes], before_family_member)
          if before_person_saved.success?
            Success({before_save_cv_family: before_save_cv_family, after_save_cv_family: cv_family.success})
          else
            Rails.logger.error { "Before Save CV Family failed due to: #{before_person_saved.failure} "}
            Success({before_save_cv_family: {}, after_save_cv_family: cv_family.success})
          end
        else
          Rails.logger.error { "Failed to construct cv family for family with hbx id: #{values[:after_save_version][:hbx_id]} due to #{cv_family.failure}" }
          Failure("Failed to construct cv family for family with hbx id: #{values[:after_save_version][:hbx_id]} due to #{cv_family.failure}")
        end
      rescue StandardError => e
        Rails.logger.error {"Error constructing cv family for family: #{family&.primary_person&.hbx_id} due to: #{e.message}, backtrace: #{e.backtrace.join("\n")}"}
        Failure("Error constructing cv family due to: #{e.message}, backtrace: #{e.backtrace.join("\n")}")
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
              end
        Success(msg)
      rescue StandardError => e
        Rails.logger.error { "Unable to generate events.person_saved event due to error: #{e.message}, backtrace: #{e.backtrace.join("\n")}" }
        Success("Unable to generate events.person_saved event due to error: #{e.message}, backtrace: #{e.backtrace.join("\n")}")
      end
    end
  end
end
