# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Migrations
    # crete taxhousehold enrollment objects
    class CreateTaxHouseholdEnrollmentsByYear
      include Dry::Monads[:result, :do]

      def call(params)
        values = yield validate(params)

        enrollments = yield fetch_enrollments_by_year(values[:year])
        create_tax_household_enrollment(enrollments)
      end

      private

      def validate(params)
        @logger = Logger.new("#{Rails.root}/log/create_tax_household_enrollments_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")

        if params[:year].blank? || !params[:year].is_a?(Integer)
          @logger.error("Invalid year #{params[:year]}")
          Failure("Invalid year #{params[:year]}")
        else
          Success(params)
        end
      end

      def fetch_enrollments_by_year(year)
        enrollments = HbxEnrollment
                      .where(
                        :effective_on.gte => Date.new(year, 0o1, 0o1),
                        :effective_on.lte => Date.new(year, 12, 31)
                      )
                      .with_aptc
                      .individual_market
                      .by_health
                      .my_enrolled_plans

        if enrollments.count > 0
          @logger.info("found #{enrollments.count} to process")
          Success(enrollments)
        else
          @logger.error("No enrollments found in the given year #{year}")
          Failure("No enrollments found in the given year #{year}")
        end
      end

      def fetch_taxhousehold_for_enrollment(enr, family)
        family.tax_households.order_by(:"eligibility_determinations.determined_at")
              .where(:"eligibility_determinations.determined_at".lte => enr.created_at).last
      end

      def create_th_member_enr_member(th_enrollment, enrollment, tax_household)
        enrollment.hbx_enrollment_members.map(&:applicant_id).each do |member_id|
          hbx_enrollment_member_id = enrollment.hbx_enrollment_members.where(applicant_id: member_id.to_s).first&.id
          tax_household_member_id = tax_household.tax_household_members.where(applicant_id: member_id.to_s).first&.id

          th_member_enr_member = th_enrollment.tax_household_members_enrollment_members.find_or_create_by(
            hbx_enrollment_member_id: hbx_enrollment_member_id&.to_s,
            tax_household_member_id: tax_household_member_id&.to_s
          )

          th_member_enr_member.update!(
            age_on_effective_date: "",
            family_member_id: "",
            relationship_with_primary: "",
            date_of_birth: ""
          )
        end
      end

      def create_tax_household_enrollment(enrollments)
        enrollments.no_timeout.each do |enr|
          family = enr.family
          tax_household = fetch_taxhousehold_for_enrollment(enr, family)

          if tax_household.present?
            th_enrollment = TaxHouseholdEnrollment.find_or_create_by(enrollment_id: enr.id, tax_household_id: tax_household.id)

            th_enrollment.update!(
              household_benchmark_ehb_premium: "",
              health_product_hios_id: "",
              dental_product_hios_id: "",
              household_health_benchmark_ehb_premium: "",
              household_dental_benchmark_ehb_premium: "",
              applied_aptc: "",
              available_max_aptc: ""
            )

            create_th_member_enr_member(th_enrollment, enr, tax_household)
          else
            @logger.info("Unable to find matching tax_household for enrollment with hbx_id #{enr.hbx_id}")
          end
        rescue StandardError => e
          @logger.error("Unable to create TaxHouseholdEnrollment for enrollment with hbx_id #{enr.hbx_id} due to #{e.inspect}")
        end
      end

    end
  end
end
