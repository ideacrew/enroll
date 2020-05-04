module Factories
  class FamilyEnrollmentCloneFactory
    include Mongoid::Document
    attr_accessor :family, :census_employee, :enrollment, :new_effective_date

    def clone_for_cobra
      raise ArgumentError if !defined?(family) || !defined?(census_employee)
      @new_effective_date = effective_on_for_cobra(enrollment)
      clone_enrollment = clone_cobra_enrollment
      clone_enrollment.decorated_hbx_enrollment
      save_clone_enrollment(clone_enrollment)
    rescue StandardError => e
      Rails.logger.error { "Unable to create cobra enrollment, Errors: #{e}" }
      raise FamilyEnrollmentCloneFactoryError, "Unable to create cobra enrollment Errors: #{e}"
    end

    def save_clone_enrollment(clone_enrollment)
      if clone_enrollment.save
        assign_enrollment_to_benefit_package_assignment(clone_enrollment)
        clone_enrollment
      else
        message = "Enrollment: #{enrollment.id}, \n" \
        "Unable to save clone enrollment: #{clone_enrollment.inspect}, \n" \
          "Error(s): \n #{clone_enrollment.errors.map { |k, v| "#{k} = #{v}" }.join(" & \n")} \n"

        raise FamilyEnrollmentCloneFactoryError, message
      end
    end

    def effective_on_for_cobra(enrollment)
      effective_on_by_terminated = census_employee.coverage_terminated_on.end_of_month + 1.days
      effective_on_by_benefit_group = enrollment.sponsored_benefit_package.effective_on_for_cobra(census_employee.hired_on)
      [effective_on_by_terminated, effective_on_by_benefit_group].max
    end

    def benefit_application
      raise FamilyEnrollmentCloneFactoryError, 'benefit package not found for enrollment' if enrollment.sponsored_benefit_package.blank?
      enrollment.sponsored_benefit_package.benefit_application
    end

    def find_renewal_ba_for_cobra_enrollment
      benefit_sponsorship = benefit_application.benefit_sponsorship
      benefit_sponsorship.benefit_applications.effective_period_cover(new_effective_date).published.where(:predecessor_id.exists => true).first
    end

    def can_create_cobra_under_renewal_py?
      raise FamilyEnrollmentCloneFactoryError, 'valid benefit application not found for the new effective date' if find_renewal_ba_for_cobra_enrollment.blank?
      benefit_packages = find_renewal_ba_for_cobra_enrollment.benefit_packages
      elected_product_ids = benefit_packages.flat_map(&:sponsored_benefits).inject([]) do |product_ids, sp_b|
        product_ids << sp_b.products(new_effective_date).flat_map(&:id)
        product_ids.flatten.compact
      end
      renewal_product = enrollment.product.renewal_product
      raise FamilyEnrollmentCloneFactoryError, "Employer Sponsored Benefits no longer offers the product #{renewal_product.title}." unless elected_product_ids.include?(renewal_product.id)
      true
    end

    def find_benefit_group_assignment
      assignment = census_employee.renewal_benefit_group_assignment
      if assignment.blank?
        census_employee.save if census_employee.active_benefit_group_assignment.blank?
        assignment = census_employee.published_benefit_group_assignment if find_renewal_ba_for_cobra_enrollment == census_employee.published_benefit_group_assignment.benefit_package.benefit_application
      end
      assignment
    end

    def clone_cobra_enrollment
      clone_enrollment = family.active_household.hbx_enrollments.new
      clone_enrollment.family = family

      if new_effective_date > benefit_application.end_on
        if can_create_cobra_under_renewal_py?
          bga = find_benefit_group_assignment
          benefit_package = bga.benefit_package
          renewal_product_id = enrollment.product.renewal_product.id
          clone_enrollment.benefit_group_assignment_id = bga.id
          clone_enrollment.sponsored_benefit_package_id = benefit_package.id
          clone_enrollment.product_id = renewal_product_id
          clone_enrollment.sponsored_benefit_id = benefit_package.sponsored_benefits.where(reference_product_id: renewal_product_id).first.id
        end
      else
        assignment = census_employee.benefit_group_assignment_by_package(enrollment.sponsored_benefit_package_id)
        clone_enrollment.benefit_group_assignment_id = assignment.id
        clone_enrollment.sponsored_benefit_package_id = enrollment.sponsored_benefit_package_id
        clone_enrollment.product_id = enrollment.product_id
        clone_enrollment.sponsored_benefit_id = enrollment.sponsored_benefit_id
      end

      clone_enrollment.employee_role_id = enrollment.employee_role_id
      clone_enrollment.predecessor_enrollment_id = enrollment.id
      clone_enrollment.coverage_kind = enrollment.coverage_kind

      clone_enrollment.kind = 'employer_sponsored_cobra'
      effective_on = effective_on_for_cobra(enrollment)
      clone_enrollment.effective_on = effective_on
      clone_enrollment.external_enrollment = enrollment.external_enrollment
      clone_enrollment.benefit_sponsorship_id = enrollment.benefit_sponsorship_id
      clone_enrollment.rating_area_id = enrollment.rating_area_id
      clone_enrollment.issuer_profile_id = enrollment.issuer_profile_id
      clone_enrollment.hbx_enrollment_members = clone_enrollment_members

      if clone_enrollment.sponsored_benefit_package.benefit_application.is_renewing?
        clone_enrollment.aasm_state = 'auto_renewing'
      else
        clone_enrollment.select_coverage
        if TimeKeeper.date_of_record >= effective_on && !enrollment.external_enrollment
          clone_enrollment.begin_coverage
        end
      end

      clone_enrollment.generate_hbx_signature
      clone_enrollment
    end

    def clone_enrollment_members
      hbx_enrollment_members = enrollment.hbx_enrollment_members
      effective_on = effective_on_for_cobra(enrollment)
      hbx_enrollment_members.inject([]) do |members, hbx_enrollment_member|
        members << HbxEnrollmentMember.new({
          applicant_id: hbx_enrollment_member.applicant_id,
          eligibility_date: effective_on,
          coverage_start_on: enrollment.effective_on,
          is_subscriber: hbx_enrollment_member.is_subscriber
        })
      end
    end

    def assign_enrollment_to_benefit_package_assignment(enrollment)
      assignment = census_employee.benefit_group_assignment_by_package(enrollment.sponsored_benefit_package_id)
      assignment.update_attributes(hbx_enrollment_id: enrollment.id)
      enrollment.update_attributes(benefit_group_assignment_id: assignment.id)
    end
  end

  class FamilyEnrollmentCloneFactoryError < StandardError; end
end
