class CcaHbxEnrollmentsMigration < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "cca"

      # Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      # file_name = "#{Rails.root}/hbx_report/enrollment_migration_status_#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
      # field_names = %w( organization_id benefit_sponsor_organization_id status)

      logger = Logger.new("#{Rails.root}/log/enrollment_migration_data.log") unless Rails.env.test?
      logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      # CSV.open(file_name, 'w') do |csv|
      #   csv << field_names

        #update enrollments to work with new model
        # update_hbx_enrollments(logger)

        puts "Check enrollment_migration_data logs & enrollment_migration_status csv for additional information." unless Rails.env.test?

      # end
      logger.info "End of the script" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down
  end

  private

  def self.update_hbx_enrollments(logger)
    ces = CensusEmployee.all
    @issuer_orga = BenefitSponsors::Organizations::Organization.issuer_profiles
    @carrier_orga = Organization.exists(carrier_profile: true)
    @products = BenefitMarkets::Products::Product.all

    begin
      ces.each do |ce|

        next unless ce.benefit_sponsorship.present?
        ce.benefit_group_assignments.each do |bga|

          enrollment = bga.hbx_enrollment
          next unless enrollment.product_id.blank? && enrollment.benefit_sponsorship_id.blank?

          #get plan_id - product_id
          next unless enrollment.plan.present?
          hios_id = enrollment.plan.hios_id
          plan_active_year = enrollment.plan.active_year
          products = @products.where(hios_id: hios_id)
          product = products.select {|product| product.application_period.min.year == plan_active_year}
          product_id = product.first.id if product.count == 1

          issuer_profile_id = nil
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
        end
      end
    rescue Exception => e
      print 'F' unless Rails.env.test?
      logger.error "Migration Failed for Organization HBX_ID: #{old_org.hbx_id},
          #{e.inspect}" unless Rails.env.test?
    end
  end
end