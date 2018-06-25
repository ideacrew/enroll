class PlanDesignOrganizationMigration < Mongoid::Migration
  def self.up
    # if Settings.site.key.to_s == "cca"
    #
    #   Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    #   file_name = "#{Rails.root}/hbx_report/pdo_migration_status_#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
    #   field_names = %w( employer_name census_emp_id benefit_group_assignment_id enrollment_id status product_id issuer_profile_id benefit_sponsorship_id sponsored_benefit_package_id sponsored_benefit_id)
    #
    #   logger = Logger.new("#{Rails.root}/log/pdo_migration_data.log") unless Rails.env.test?
    #   logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?
    #
    #   CSV.open(file_name, 'w') do |csv|
    #     csv << field_names
    #
    #     # update enrollments to work with new model
    #     update_plan_design_organization(csv, logger)
    #
    #     puts "" unless Rails.env.test?
    #     puts "Check epdo_migration_data logs & pdo_migration_status csv for additional information." unless Rails.env.test?
    #
    #   end
    #   logger.info "End of the script" unless Rails.env.test?
    # else
    #   say "Skipping for non-CCA site"
    # end
  end

  def self.down
  end

  private

  def self.update_plan_design_organization(csv, logger)
    pdos = SponsoredBenefits::Organizations::PlanDesignOrganization.all

    @emp_orgs = BenefitSponsors::Organizations::Organization.employer_profiles
    @bk_orgs = BenefitSponsors::Organizations::Organization.broker_agency_profiles

    #counters
    total_enrollments = 0
    updated_enrollments = 0

    sponsor_profile_id = nil
    owner_profile_id = nil
    pdos.batch_size(1000).no_timeout.all.each do |pdo|
      begin

        next unless pdo.sponsor_profile_id.present?
        if pdo.sponsor_profile_id.present?
          employer_profile = @emp_orgs.where(fein: pdo.fein).first.employer_profile
          sponsor_profile_id = employer_profile._id
        end

        orga = SponsoredBenefits::Organizations::Organization.all.where(:"broker_agency_profile._id" => pdo.broker_agency_profile_id).first

        if orga.present?
          new_org = @bk_orgs.broker_by_hbx_id(orga.hbx_id)
          owner_profile_id = new_org.first.broker_agency_profile._id if new_org.present?
        end

        pdo.update_attributes!(owner_profile_id: owner_profile_id,
                               sponsor_profile_id: sponsor_profile_id
        )

      rescue Exception => e
        print 'F' unless Rails.env.test?
        csv << [ce.employer_profile.legal_name, ce.id, bga.id, enrollment.id, "failed", enrollment.product_id, enrollment.issuer_profile_id, enrollment.benefit_sponsorship_id, enrollment.sponsored_benefit_package_id, enrollment.sponsored_benefit_id]
        logger.error "update failed for HBX Enrollment: #{enrollment.id},
            #{e.inspect}" unless Rails.env.test?
      end
    end
    # logger.info " Total #{total_enrollments} enrollments for census employees" unless Rails.env.test?
    # logger.info " #{updated_enrollments} enrollments updated at this point." unless Rails.env.test?
    return true
  end
end