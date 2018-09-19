require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateProductPackageRates < MongoidMigrationTask
  def migrate
    begin
    feins = "#{ENV['feins']}".split(',').uniq
    feins.each do |fein|
      org = ::BenefitSponsors::Organizations::Organization.where(fein: fein).first
      benefit_application = org.employer_profile.benefit_applications.where(:aasm_state.in => BenefitSponsors::BenefitApplications::BenefitApplication::PUBLISHED_STATES)
      if (benefit_application.count == 0)
      puts "Found no Benefit Applications in PUBLISHED STATES"
      else
        benefit_application.each do |ba|
          product_packages = ba.benefit_sponsor_catalog.product_packages
          product_packages.each do |product_package|
          hios_ids = product_package.products.map(&:hios_id).uniq
          products = ::BenefitMarkets::Products::Product.where(:hios_id.in => hios_ids).select{|a| a.active_year == 2018}
          product_package.products = products
          product_package.save
          puts "Product Package Updated for the fein => #{fein}"  unless Rails.env.test?
          end
        end
      end
    end
    rescue => e
      puts "#{e}"
    end
  end
end