# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module Pvc
        # operation to manually trigger pvc events.
        # It will take families as input and find the determined application, add evidences and publish the group of applications
        class SubmitPvcSet
          include Dry::Monads[:result, :do]
          include EventSource::Command
          include EventSource::Logging
          include FinancialAssistance::JobsHelper

          # "02", "04", "05", "06" are already converted
          PVC_CSR_LIST = [100, 73, 87, 94].freeze

          # @param [Int] assistance_year
          # @param [Array] csr_list
          # @return [ Success ] Job successfully completed
          def call(params)
            start_time = process_start_time
            values = yield validate(params)
            families = find_families(values)
            manifest = make_manifest(families, values[:assistance_year])
            submit(params, families, manifest)
            end_time = process_end_time_formatted(start_time)
            logger.info "Successfully submitted #{manifest[:count]} members for PVC in #{end_time}"
            puts "Successfully submitted #{manifest[:count]} members for PVC in #{end_time}"
            Success("Successfully Submitted PVC Set")
          end

          private

          def validate(params)
            errors = []
            errors << 'assistance_year ref missing' unless params[:assistance_year]
            params[:csr_list] = PVC_CSR_LIST if params[:csr_list].blank?
            errors.empty? ? Success(params) : Failure(errors)
          end

          def get_count(families)
            match_stage = { '$match' => { '_id' => { '$in' => families }} }
            unwind_stage = { '$unwind' => { "path" => "$family_members" } }
            count_stage = { '$count' => 'total' }
            Family.collection.aggregate([match_stage, unwind_stage, count_stage]).first&.dig("total")
          end

          def make_manifest(families, assistance_year)
            params = {
              type: "pvc_manifest_type",
              assistance_year: assistance_year,
              initial_count: get_count(families)
            }
            ::AcaEntities::Pdm::Contracts::ManifestContract.new.call(params).to_h
          end

          def find_families(params)
            Family.periodic_verifiable_for_assistance_year(params[:assistance_year], params[:csr_list]).distinct(:_id)
          end

          def submit(_params, family_ids, manifest)
            families = Family.where(:_id.in => family_ids)
            families.each do |family|
              family.family_members.each do |member|
                publish({manifest: manifest, person: member.person, family_id: family.id})
              end
            end
          end

          def build_event(payload)
            event('events.iap.applications.request_family_pvc_determination', attributes: payload)
          end

          def publish(payload)
            event = build_event(payload)
            event.success.publish

            Success("Successfully published the pvc payload")
          end
        end
      end
    end
  end
end
