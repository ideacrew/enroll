# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    module IapApplications
      module Rrvs
        module IncomeEvidences
          # This operation is to build determination request for rrv ifsv outbound
          class BuildDeterminationRequest
            include Dry::Monads[:result, :do]
            include EventSource::Command
            include EventSource::Logging

            def call(assistance_year: (TimeKeeper.date_of_record.year + 1))
              families = yield find_families(assistance_year)
              result   = yield build_determination_requests(families, assistance_year)

              Success(result)
            end

            private

            def find_families(assistance_year)
              family_ids = ::FinancialAssistance::Application.where(:aasm_state => "determined",
                                                                    :assistance_year => assistance_year,
                                                                    :"applicants.is_ia_eligible" => true).distinct(:family_id)
              if family_ids.present?
                Success(Family.where(:_id.in => family_ids))
              else
                Failure("No determined applications with ia_eligible applicants found in assistance_year #{assistance_year}")
              end
            end

            def fetch_application(family, assistance_year)
              ::FinancialAssistance::Application.where(:family_id => family.id,
                                                       :assistance_year => assistance_year,
                                                       :aasm_state => 'determined',
                                                       :"applicants.is_ia_eligible" => true).max_by(&:created_at)
            end

            def build_event(payload)
              event('events.families.iap_applications.rrvs.income_evidences.determination_build_requested', attributes: payload)
            end

            def publish_event(family, application)
              payload = { application_hbx_id: application.hbx_id, family_hbx_id: family.hbx_assigned_id }
              event = build_event(payload)
              event.success.publish
            end

            def build_determination_requests(families, assistance_year)
              rrv_logger = Logger.new("#{Rails.root}/log/rrv_ifsv_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
              count = 0
              families.no_timeout.each do |family|
                determined_application = fetch_application(family, assistance_year)
                next unless determined_application.present? && determined_application.aptc_applicants.present?

                publish_event(family, determined_application)
                count += 1
                rrv_logger.info("********************************* processed #{count} families *********************************") if count % 100 == 0
              rescue StandardError => e
                rrv_logger.error("failed to process for person with hbx_id #{family.primary_person.hbx_id} due to #{e.inspect}")
              end
              Success("published #{count} families")
            end
          end
        end
      end
    end
  end
end
