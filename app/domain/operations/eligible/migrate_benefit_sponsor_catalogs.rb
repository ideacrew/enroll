# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module Eligible
    # Operation to migrate benefit sponsor catalog
    class MigrateBenefitSponsorCatalog
      include Dry::Monads[:do, :result]

      # @param [Hash] opts Options to migrate benefit sponsor catalog
      # @option opts [<String>]   :sponsorship_id required
      # @return [Dry::Monad] result
      def call(params)
        benefit_sponsorship = yield find_sponsorship(params)
        applications = yield verify_migration_eligible(benefit_sponsorship)
        _errors = yield validate_applications(benefit_sponsorship, applications)
        catalogs = yield update_catalog(benefit_sponsorship, applications)

        Success(catalogs)
      end

      private

      def find_sponsorship(values)
        subject = GlobalID::Locator.locate(values[:sponsorship_id])

        Success(subject)
      end

      def verify_migration_eligible(benefit_sponsorship)
        applications = []
        applications_for(benefit_sponsorship).each do |application|
          start_on = application.start_on
          eligibility = benefit_sponsorship.eligibility_on(start_on)

          next unless eligibility
          next unless calendar_years.include?(start_on.year)
          next unless application.created_at > eligibility.created_at
          applications << application
        end

        if applications.present?
          Success(applications)
        else
          Failure("no applications found")
        end
      end

      def validate_applications(benefit_sponsorship, applications)
        errors = []

        logger.info "validating  #{benefit_sponsorship.legal_name}(#{benefit_sponsorship.fein})"
        applications.each do |application|
          non_metal_level_product_package =
            application.benefit_packages.any? do |benefit_package|
              benefit_package
                .health_sponsored_benefit
                &.product_package_kind
                .to_s != "metal_level"
            end

          errors << "found non metal level product package for application #{application.start_on} #{application.aasm_state}" if non_metal_level_product_package

          application_with_bronze_ref_plan =
            application.benefit_packages.any? do |benefit_package|
              benefit_package
                .health_sponsored_benefit
                &.reference_product
                &.metal_level_kind
                .to_s == "bronze"
            end

          errors << "found bronze reference plan for application #{application.start_on} #{application.aasm_state}" if application_with_bronze_ref_plan

          verify_bronze_plan_coverages(application, errors)
          verify_employee_subsidies(application, errors)
        end
        return Success(errors) unless errors.present?
        logger.info "failed validation due to #{errors.inspect}"
        Failure(errors)
      end

      def verify_bronze_plan_coverages(application, errors)
        employees_enrolled_in_bronze_plan =
          application.benefit_packages.any? do |benefit_package|
            enrolled_families(benefit_package).any? do |family|
              enrollments_by_package(family, benefit_package).any? do |en|
                en.product&.metal_level_kind.to_s == "bronze"
              end
            end
          end

        errors << "found employees enrolled in bronze plan for application #{application.start_on} #{application.aasm_state}" if employees_enrolled_in_bronze_plan
      end

      def verify_employee_subsidies(application, errors)
        all_employees_without_osse =
          application.benefit_packages.any? do |benefit_package|
            enrolled_families(benefit_package).all? do |family|
              enrollments_by_package(family, benefit_package).none? do |en|
                en.eligible_child_care_subsidy > 0
              end
            end
          end
        errors << "found no employees with subsidy for application #{application.start_on} #{application.aasm_state}" if all_employees_without_osse
      end

      def enrolled_families(benefit_package)
        benefit_package.enrolled_and_terminated_families
      end

      def enrollments_by_package(family, benefit_package)
        enrollments =
          family.hbx_enrollments.by_health.by_benefit_package(benefit_package)

        enrollments.enrolled_waived_terminated_and_expired.where(
          :aasm_state.nin => HbxEnrollment::WAIVED_STATUSES
        )
      end

      def update_catalog(benefit_sponsorship, applications)
        logger.info "updating catalog for #{benefit_sponsorship.legal_name}(#{benefit_sponsorship.fein})"
        catalogs =
          applications.collect do |application|
            logger.info "updating application catalog for #{application.start_on} #{application.aasm_state}"
            update_application_catalog(application)
            logger.info "updated application catalog for #{application.start_on} #{application.aasm_state}"
            application.benefit_sponsor_catalog
          end

        Success(catalogs)
      end

      def update_application_catalog(application)
        sponsor_catalog = application.benefit_sponsor_catalog

        catalog =
          collection.find({ _id: BSON.ObjectId(sponsor_catalog.id.to_s) }).first

        packages = catalog["product_packages"]
        packages.delete_if do |package|
          package["product_kind"] == :health &&
            package["package_kind"] != :metal_level
        end

        packages.each do |package|
          next if package["product_kind"] == :dental
          next unless package["package_kind"] == :metal_level
          package["products"].delete_if do |product|
            product["metal_level_kind"] == :bronze
          end
        end

        catalog["product_packages"] = packages
        collection.update_one({ _id: catalog["_id"] }, catalog)
        sponsor_catalog.reload
        sponsor_catalog.create_sponsor_eligibilities
      end

      def logger
        unless defined?(@logger)
          @logger =
            Logger.new(
              "#{Rails.root}/log/migrate_benefit_sponsor_catalogs_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
            )
        end
        @logger
      end

      def applications_for(benefit_sponsorship)
        application_states =
          ::BenefitSponsors::BenefitApplications::BenefitApplication::SUBMITTED_STATES +
          [:terminated]

        benefit_sponsorship.benefit_applications.where(
          :aasm_state.in => application_states
        )
      end

      def db
        return @db if defined?(@db)
        @db = Mongoid::Clients.default
      end

      def collection
        return @collection if defined?(@collection)
        @collection = db[:benefit_markets_benefit_sponsor_catalogs]
      end

      def calendar_years
        [Date.today.year - 1, Date.today.year]
      end
    end
  end
end
