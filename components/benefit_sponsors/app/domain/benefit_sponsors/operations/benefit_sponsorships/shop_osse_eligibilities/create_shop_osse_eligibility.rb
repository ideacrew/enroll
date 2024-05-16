# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibilities
        # Operation to support eligibility creation
        class CreateShopOsseEligibility
          include Dry::Monads[:do, :result]

          attr_accessor :subject, :default_eligibility, :prospective_eligibility

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
            eligibility = yield create_eligibility(eligibility_options)
            eligibility_record = yield store(values, eligibility)
            _event = yield publish_event(eligibility_record)

            Success(eligibility_record)
          end

          private

          def validate(params)
            params[:effective_date] ||= TimeKeeper.date_of_record

            errors = []
            errors << "evidence key missing" unless params[:evidence_key]
            errors << "evidence value missing" unless params[:evidence_value]
            errors << "effective date missing" unless params[:effective_date].is_a?(::Date)
            @subject = GlobalID::Locator.locate(params[:subject])
            errors << "subject missing or not found for #{params[:subject]}" unless @subject.present?
            if subject.respond_to?(:market_kind) &&
               subject.market_kind != :aca_shop
              errors << "subject should belong to shop market"
            end

            errors.empty? ? Success(params) : Failure(errors)
          end

          # Given calendar year there will be only one instance of osse eligibility with single evidence record.
          # When eligibility changes we create new state histories for evidence and eligibility
          def find_eligibility(values)
            eligibility =
              subject
              .eligibilities
              .by_key(
                "aca_shop_osse_eligibility_#{values[:effective_date].year}".to_sym
              )
              .last

            Success(eligibility)
          end

          def build_eligibility_options(values, eligibility_record = nil)
            ::Operations::Eligible::BuildEligibility.new(
              configuration:
                BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::ShopOsseEligibilityConfiguration.new(
                  subject: subject,
                  effective_date: values[:effective_date]
                )
            ).call(
              values.merge(
                eligibility_record: eligibility_record,
                evidence_configuration:
                  BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::ShopOsseEvidenceConfiguration.new
              )
            )
          end

          # Following Operation expects AcaEntities domain class as subject
          def create_eligibility(eligibility_options)
            AcaEntities::Eligible::AddEligibility.new.call(
              subject:
                "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship",
              eligibility: eligibility_options
            )
          end

          def store(_values, eligibility)
            eligibility_record =
              subject.eligibilities.where(id: eligibility._id).first

            if eligibility_record
              update_eligibility_record(eligibility_record, eligibility)
            else
              eligibility_record = create_eligibility_record(eligibility)
              subject.eligibilities << eligibility_record
            end

            if subject.save
              Success(eligibility_record.reload)
            else
              Failure(subject.errors.full_messages)
            end
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

            eligibility_record.save
            subject.save
          end

          def build_history_params_for(record)
            record_history = record.state_histories.last
            record_history.to_h
          end

          def create_eligibility_record(eligibility)
            osse_eligibility_params =
              eligibility.to_h.except(:evidences, :grants)

            eligibility_record =
              BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::ShopOsseEligibility.new(
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

          def publish_event(eligibility)
            event_name = eligibility_event_for(eligibility.current_state)
            return Succcess(eligibility) unless event_name

            ::Operations::EventLogs::TrackableEvent.new.call({
                                                               event_name: event_name,
                                                               payload: eligibility.attributes.to_h,
                                                               subject: eligibility.eligible.organization,
                                                               resource: eligibility
                                                             })
          end

          def eligibility_event_for(current_state)
            return false if default_eligibility
            return 'events.benefit_sponsors.benefit_sponsorships.eligibilities.shop_osse_eligibility.eligibility_renewed' if prospective_eligibility

            case current_state
            when :eligible
              'events.benefit_sponsors.benefit_sponsorships.eligibilities.shop_osse_eligibility.eligibility_created'
            when :ineligible
              'events.benefit_sponsors.benefit_sponsorships.eligibilities.shop_osse_eligibility.eligibility_terminated'
            end
          end
        end
      end
    end
  end
end
