class CcaHbxEnrollmentsMigration < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "cca"

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/enrollment_migration_status_#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
      field_names = %w( census_emp_id total_benefit_group_assignment_id enrollment_id status product_id issuer_profile_id benefit_sponsorship_id)

      logger = Logger.new("#{Rails.root}/log/enrollment_migration_data.log") unless Rails.env.test?
      logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      CSV.open(file_name, 'w') do |csv|
        csv << field_names

        # update enrollments to work with new model
        # update_hbx_enrollments(csv, logger)

        puts "Check enrollment_migration_data logs & enrollment_migration_status csv for additional information." unless Rails.env.test?

      end
      logger.info "End of the script" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down
  end

  private

  def self.update_hbx_enrollments(csv, logger)
    ces = CensusEmployee.all
    @issuer_orga = BenefitSponsors::Organizations::Organization.issuer_profiles
    @carrier_orga = Organization.exists(carrier_profile: true)
    @products = BenefitMarkets::Products::Product.all

    #counters
    total_ces = ces.count
    total_benefit_group_assignments = 0
    total_enrollments = 0
    updated_enrollments = 0

    begin
      ces.each do |ce|

        next unless ce.benefit_sponsorship.present?
        ce.benefit_group_assignments.each do |bga|

          benefit_sponsorship_id = nil
          product_id = nil
          issuer_profile_id = nil
          total_enrollments = total_enrollments + 1

          enrollment = bga.hbx_enrollment

          #get plan_id - product_id
          if enrollment.plan.present?
            hios_id = enrollment.plan.hios_id
            plan_active_year = enrollment.plan.active_year
            products = @products.where(hios_id: hios_id)
            product = products.select {|product| product.application_period.min.year == plan_active_year}
            product_id = product.first.id if product.count == 1

            #get carrier_profile_id - issuer_profile_id
            if enrollment.carrier_profile_id.present?
              carrier_profile_id = enrollment.carrier_profile_id
              carrier_profile_hbx_id = @carrier_orga.where(id: carrier_profile_id).first.hbx_id
              issuer_profile_id = @issuer_orga.where(hbx_id: carrier_profile_hbx_id).first.id
            end


            #get benefit_sponsorship_id
            benefit_sponsorship_id = ce.benefit_sponsorship.id

            enrollment.update_attributes(product_id: product_id, issuer_profile_id: issuer_profile_id, benefit_sponsorship_id: benefit_sponsorship_id)
            print '.' unless Rails.env.test?
            updated_enrollments = updated_enrollments + 1
            csv << [ce.id, bga.id, enrollment.id, "updated", product_id, issuer_profile_id, benefit_sponsorship_id]
          else
            csv << [ce.id, bga.id, enrollment.id, "skipped as no plan id present for enrollment", product_id, issuer_profile_id, benefit_sponsorship_id]
          end
        end
      end
    rescue Exception => e
      print 'F' unless Rails.env.test?
      csv << [ce.id, bga.id, enrollment.id, "failed", product_id, issuer_profile_id, benefit_sponsorship_id]
      logger.error "update failed for HBX Enrollment: #{enrollment.id},
          #{e.inspect}" unless Rails.env.test?
    end
    logger.info " Total #{total_enrollments} enrollments for census employees" unless Rails.env.test?
    logger.info " #{updated_enrollments} enrollments updated at this point." unless Rails.env.test?
    return true
  end
end