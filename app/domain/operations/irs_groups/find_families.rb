# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module IrsGroups
    # Publish event on finding enrolled family
    class FindFamilies
      include Dry::Monads[:do, :result]
      include EventSource::Command

      def call(params)
        values              = yield validate(params)
        enrolled_families   = yield enrolled_families_in_date_range(values)
        result              = yield publish_families(enrolled_families)

        Success(result)
      end

      private

      def validate(params)
        errors = []
        errors << "start_date #{params[:start_date]} is not a valid Date" unless params[:start_date].is_a?(Date)
        errors << "end_date #{params[:end_date]} is not a valid Date" unless params[:end_date].is_a?(Date)

        errors.empty? ? Success(params) : Failure(errors)
      end

      def enrolled_families_in_date_range(params)
        enrolled_family_ids = HbxEnrollment.by_health.enrolled_and_terminated.by_effective_date_range(params[:start_date], params[:end_date]).distinct(:family_id)
        enrolled_families = Family.where(:_id.in => enrolled_family_ids)

        enrolled_families.count > 0 ? Success(enrolled_families) : Failure("No enrolled Families by health in given date range")
      end

      def publish_families(families)
        logger = Logger.new("#{Rails.root}/log/irs_groups_find_families_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
        total_families_count = families.count
        counter = 0

        logger.info("Operation started at #{DateTime.now} ")
        families.no_timeout.each do |family|
          event = event("events.irs_groups.family_found", attributes: {family_id: family.id})
          event.success.publish
          counter += 1
          logger.info("published #{counter} out of #{total_families_count}") if counter % 100 == 0
        rescue StandardError => e
          logger.info("unable to publish family with hbx_id #{family.hbx_assigned_id} due to #{e.inspect}")
        end
        logger.info("Operation ended at #{DateTime.now} ")
        Success("published all enrolled families")
      end

    end
  end
end
