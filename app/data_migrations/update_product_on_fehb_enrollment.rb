require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateProductOnFehbEnrollment < MongoidMigrationTask

  def migrate
    begin

    feins = "#{ENV['feins']}".split(',').uniq

    feins.each do |fein|
      organization = ::BenefitSponsors::Organizations::Organization.where(fein: fein).first
      employer_profile = organization.employer_profile
      employer_profile.census_employees.each do |ce|
        if ce.employee_role.present?
          person = ce.employee_role.person
          enrollments = enrollments_effective_on(person, Date.new(2019,1,1))
          enrollments.each do |enrollment|
            next unless enrollment.fehb_profile.present?

            current_product = enrollment.product
            next if current_product && current_product.benefit_market_kind.to_s == 'fehb'

            fehb_product = BenefitMarkets::Products::Product.where(
                            :hios_base_id => /#{current_product.hios_id}/,
                            :"application_period.min".gte => Date.new(current_product.active_year, 1, 1), :"application_period.max".lte => Date.new(current_product.active_year, 1, 1).end_of_year,
                            :kind => current_product.kind,
                            :benefit_market_kind => :fehb
                          ).first
            enrollment.update_attributes(:product_id => fehb_product.id) if fehb_product.present?
          end
        end
      end
    end
    rescue Exception => e
      puts e.message
    end
  end

  def enrollments_effective_on(person, effective_date)
    person.primary_family.active_household.hbx_enrollments.shop_market.where(:effective_on.gte => effective_date, :aasm_state.nin => ["shopping", "coverage_canceled"])
  end
end
