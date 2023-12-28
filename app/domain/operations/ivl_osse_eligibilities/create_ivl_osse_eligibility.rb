# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module IvlOsseEligibilities
    # Operation to support IVL osse eligibility creation
    class CreateIvlOsseEligibility
      send(:include, Dry::Monads[:result, :do])
      include EventSource::Command
      include EventSource::Logging

      attr_accessor :subject, :default_eligibility

      # @param [Hash] opts Options to build eligibility
      # @option opts [<GlobalId>] :subject required
      # @option opts [<String>]   :evidence_key required
      # @option opts [<String>]   :evidence_value required
      # @option opts [Date]       :effective_date required
      # @option opts [Hash]       :timestamps optional timestamps for data migrations purposes
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        eligibility_record = yield find_eligibility(values)
        eligibility_options =
          yield build_eligibility_options(values, eligibility_record)
        eligibility = yield create_eligibility(values, eligibility_options)
        eligibility_record = yield store(values, eligibility)
        event = yield create_event(eligibility_record)
        _result = yield publish_event(event)

        Success(eligibility_record)
      end

      private

      def validate(params)
        params[:effective_date] ||= TimeKeeper.date_of_record

        errors = []
        errors << "evidence key missing" unless params[:evidence_key]
        errors << "evidence value missing" unless params[:evidence_value]
        unless params[:effective_date].is_a?(::Date)
          errors << "effective date missing or it should be a date"
        end
        @subject = GlobalID::Locator.locate(params[:subject])
        unless subject.present?
          errors << "subject missing or not found for #{params[:subject]}"
        end

        errors.empty? ? Success(params) : Failure(errors)
      end

      # For a given calendar year there will be only one instance of OSSE eligibility with only one evidence instance.
      # We'll be adding State Histories when the eligibility changes
      def find_eligibility(values)
        eligibility =
          subject
            .eligibilities
            .by_key(
              "aca_ivl_osse_eligibility_#{values[:effective_date].year}".to_sym
            )
            .last

        Success(eligibility)
      end

      def build_eligibility_options(values, eligibility_record = nil)
        ::Operations::Eligible::BuildEligibility.new(
          configuration:
            ::Operations::IvlOsseEligibilities::IvlOsseEligibilityConfiguration.new(
              values[:effective_date]
            )
        ).call(
          values.merge(
            eligibility_record: eligibility_record,
            evidence_configuration:
              ::Operations::IvlOsseEligibilities::IvlOsseEvidenceConfiguration.new
          )
        )
      end

      # Following Operation expects AcaEntities domain class as subject
      def create_eligibility(_values, eligibility_options)
        AcaEntities::Eligible::AddEligibility.new.call(
          subject: "AcaEntities::People::#{subject.class.to_s.demodulize}",
          eligibility: eligibility_options
        )
      end

      def store(_values, eligibility)
        eligibility_record =
          subject.eligibilities.where(id: eligibility._id).first

        if eligibility_record
          update_eligibility_record(eligibility_record, eligibility)
          eligibility_record.save
        else
          eligibility_record = create_eligibility_record(eligibility)
          subject.eligibilities << eligibility_record
        end

        save_proc =
          proc do
            if subject.save
              Success(eligibility_record)
            else
              Failure(subject.errors.full_messages)
            end
          end

        if subject.is_a?(ConsumerRole)
          ConsumerRole.skip_callback(:update, :after, :publish_updated_event)
        end
        output =
          if default_eligibility
            Person.without_callbacks(callbacks_to_skip, &save_proc)
          else
            save_proc.call
          end
        if subject.is_a?(ConsumerRole)
          ConsumerRole.set_callback(:update, :after, :publish_updated_event)
        end

        output
      end

      def callbacks_to_skip
        callbacks = []
        callbacks << %i[update after notify_updated]
        callbacks << %i[update after person_create_or_update_handler]
        callbacks << %i[update after publish_updated_event]
        callbacks << %i[save after generate_person_saved_event]
        callbacks
      end

      def update_eligibility_record(eligibility_record, eligibility)
        evidence = eligibility.evidences.last
        evidence_history_params = build_history_params_for(evidence)
        eligibility_history_params = build_history_params_for(eligibility)

        evidence_record = eligibility_record.evidences.last
        evidence_record.is_satisfied = evidence.is_satisfied
        evidence_record.current_state = evidence.current_state
        evidence_record.state_histories.build(evidence_history_params)
        eligibility_record.state_histories.build(eligibility_history_params)
        eligibility_record.current_state = eligibility.current_state
      end

      def build_history_params_for(record)
        record_history = record.state_histories.last
        record_history.to_h
      end

      def create_eligibility_record(eligibility)
        osse_eligibility_params = eligibility.to_h.except(:evidences, :grants)

        eligibility_record =
          ::IvlOsseEligibilities::IvlOsseEligibility.new(
            osse_eligibility_params
          )

        eligibility_record.tap do |record|
          record.evidences =
            record.class.create_objects(eligibility.evidences, :evidences)
          record.grants =
            record.class.create_objects(eligibility.grants, :grants)
        end

        eligibility_record
      end

      def create_event(eligibility)
        event_name = eligibility_event_for(eligibility.current_state)
        trackable_event = Operations::EventLogs::TrackableEvent.new(event_name, payload: eligibility.attributes.to_h)
        result = trackable_event.tap do |event|
          event.market_kind = 'individual'
          event.subject = eligibility.eligible
          event.resource = eligibility
        end.build

        unless Rails.env.test?
          logger.info("-" * 100)
          logger.info(
            "Enroll Reponse Publisher to external systems,
            event_key: #{event_name}, attributes: #{eligibility.attributes.to_h}, result: #{result}"
          )
          logger.info("-" * 100)
        end

        result
      end

      def publish_event(event)
        Success(event.publish)
      end

      def eligibility_event_for(current_state)
        if current_state == :eligible
          "events.hc4cc.eligibility_created"
        elsif current_state == :ineligible
          "events.hc4cc.eligibility_terminated"
        end
      end
    end
  end
end


# subject = Person.exists(:consumer_role => true).first.consumer_role

# options = {
#   subject_gid: subject.person.to_global_id,
#   record_gid: subject.to_global_id,
#   event_category: "hc4cc_eligibility",
#   correlation_id: SecureRandom.uuid,
#   message_id: SecureRandom.uuid,
#   event_name: 'events.hc4cc.eligibility_created',
#   event_outcome: 'eligibility_created',
#   account_id: subject.person.user.id,
#   event_time: DateTime.now,
#   aggregated_event_log: {
#     event_category: "hc4cc_eligibility",
#     market_kind: "individual",
#     subject_hbx_id: subject.person.hbx_id,
#     event_category: "hc4cc_eligibility",
#     event_time: DateTime.now,
#     login_session_id: "1234"
#   }
# }

# person_log = EventLogs::PersonEventLog.new(options)
# person_log.event_loggable.build(options[:event_loggable])
# person_log.save

# # comments_with_posts = EventLogs::AggregatedEventLog.includes(:aggregatable).where(:created_at.gte => 1.hour.ago)

# write specs and operatios
# write operations that perists data into db
