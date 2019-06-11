class MigrateDcHbxEnrollments < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "dc"
      @logger = Logger.new("#{Rails.root}/log/enrollment_migration_data.log") unless Rails.env.test?
      @logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      update_hbx_enrollments

      puts "Check enrollment_migration_data logs & enrollment_migration_status csv for additional information." unless Rails.env.test?
      @logger.info "End of the script" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down

  end


  private

  def self.update_hbx_enrollments

    say_with_time("Time taken to build data hash") do

      @benefit_app_hash ={}
      BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:'benefit_applications'.exists=>true).each do |bs|
        bs.benefit_applications.each do |ba|
          ba.benefit_groups.each do |bg|
            bg_hash = {}
            bg_hash[bg.id] = {'benefit_sponsorship_id' => bs.id,'health_sponsored_benefit_id' => bg.health_sponsored_benefit.id, "rating_area_id" => ba.recorded_rating_area_id}
            bg_hash[bg.id].merge!({'dental_sponsored_benefit_id' => bg.dental_sponsored_benefit.id }) if bg.dental_sponsored_benefit.present?
            @benefit_app_hash.merge!(bg_hash)
          end
        end
      end

      @plan_hash ={}
      BenefitMarkets::Products::Product.where(benefit_market_kind: :aca_shop).each do |product|
        hios_id = product.hios_id
        year = product.active_year
        plan = Plan.where(hios_id: hios_id, active_year: year).first
        @plan_hash[plan.id] = {"product_id" => product.id, "carrier_profile_id" => product.issuer_profile_id}
      end
    end

    say_with_time("Time taken to shop enrollments") do

      ce_count = CensusEmployee.all.exists(benefit_group_assignments: true).count
      offset_count = 0
      limit_count = 1000

      while (offset_count <= ce_count) do
        puts "offset_count: #{offset_count}"
        CensusEmployee.all.exists(benefit_group_assignments: true).limit(limit_count).offset(offset_count).each do |ce|
          begin
            ce.benefit_group_assignments.each do |bga|
              benefit_package_id = bga.benefit_package_id
              get_hbx_enrollments(bga).each do |hbx|
                benefit_app_data = @benefit_app_hash[benefit_package_id]
                product_data = @plan_hash[hbx.plan_id]
                if benefit_app_data && product_data
                  hbx.update_attributes(
                      product_id: product_data['product_id'],
                      issuer_profile_id: product_data['carrier_profile_id'],
                      benefit_sponsorship_id: benefit_app_data['benefit_sponsorship_id'],
                      sponsored_benefit_package_id: benefit_package_id,
                      sponsored_benefit_id: hbx.coverage_kind == "health" ? benefit_app_data['health_sponsored_benefit_id'] : benefit_app_data['dental_sponsored_benefit_id'],
                      rating_area_id: benefit_app_data["rating_area_id"]
                  )
                  print '.' unless Rails.env.test?
                elsif !(hbx.shopping? ||hbx.coverage_canceled? || hbx.renewing_waived?)
                  print 'F' unless Rails.env.test?
                  @logger.error "benefit application reference not found enrollment: #{hbx.hbx_id} -- #{hbx.employer_profile.legal_name}"
                end
              end
            end
          rescue => e
            print 'F' unless Rails.env.test?
            @logger.error "Update failed for Shop HBX Enrollment Census Employee id: #{ce.employer_profile.legal_name},
            #{e.message}" unless Rails.env.test?
          end
        end
        offset_count += limit_count
      end
    end

    say_with_time("Time taken to IVL enrollments") do
      f_count = Family.where(:'households.hbx_enrollments'.exists=>true, :"households.hbx_enrollments.kind".nin=> ['employer_sponsored', 'employer_sponsored_cobra']).count
      offset_count = 0
      limit_count = 1000

      while (offset_count <= f_count) do
        puts "offset_count: #{offset_count}"
        Family.where(:'households.hbx_enrollments'.exists=>true, :"households.hbx_enrollments.kind".nin=> ['employer_sponsored', 'employer_sponsored_cobra']).limit(limit_count).offset(offset_count).each do |fam|
          begin
            fam.active_household.hbx_enrollments.each do |hbx|
              next if hbx.is_shop?
              product_data = @plan_hash[hbx.plan_id]
              if product_data
                hbx.update_attributes(
                    product_id: product_data['product_id'],
                    issuer_profile_id: product_data['carrier_profile_id']
                )
                print '.' unless Rails.env.test?
              elsif !(hbx.shopping? ||hbx.coverage_canceled? || hbx.renewing_waived?)
                print 'F' unless Rails.env.test?
                @logger.error "IVL enrollment reference not found hbx_id: #{hbx.hbx_id}"
              end
            end
          rescue => e
            print 'F' unless Rails.env.test?
            @logger.error "Update failed for IVL HBX Enrollment family id: #{fam.id},
            #{e.message}" unless Rails.env.test?
          end
        end
        offset_count += limit_count
      end
    end
    reset_hash
  end

  def self.get_hbx_enrollments(bga)
    bga.covered_families.inject([]) do |enrollments, family|
      family.households.each do |household|
        enrollments += household.hbx_enrollments.select do |enrollment|
          enrollment.benefit_group_assignment_id == bga.id
        end.to_a
      end
      enrollments
    end
  end

  def self.reset_hash
    @plan_hash ={}
    @benefit_app_hash ={}
  end

end