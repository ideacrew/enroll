require 'csv'

file_name = "#{Rails.root}/#{ARGV[0]}"

field_names = %w(
        enrollment_id
        hios_id
        aasm_state
        person_hbx_id
        person_full_name
        reason
      )
report_name = "#{Rails.root}/enrollments_not_updated_list_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

def process_enrollments(file_name, csv)
  begin
    CSV.foreach(file_name, headers: true, header_converters: :symbol).each do |row|
      row_hash = row.to_hash
      enrollment = HbxEnrollment.by_hbx_id(row_hash[:hbx_enrollment_id]).first
      enrollment_effective_year = enrollment.effective_on.year
      enrollment_product_year = enrollment&.product.application_period.min.year
      profile = enrollment&.employer_profile

      person_hbx_id = enrollment&.subscriber&.person.hbx_id

      benefit_market_kind = is_fehb_employer?(profile) ? :fehb : :aca_shop

      sponsored_product_ids = enrollment&.sponsored_benefit&.product_package.products.pluck(:id)

      products = BenefitMarkets::Products::Product.by_year(enrollment_effective_year).where(hios_id: row_hash[:hios_id], benefit_market_kind: benefit_market_kind)


      benefit_packages = enrollment&.employer_profile&.benefit_applications.by_year(enrollment_effective_year).first&.benefit_packages


      unless row_hash[:hios_id].present?
        csv << [row_hash[:hbx_enrollment_id], row_hash[:hios_id], enrollment.aasm_state, enrollment&.subscriber&.person.hbx_id, enrollment&.subscriber&.person.full_name, enrollment.coverage_kind, "enrollment not found in glue"]
        next
      end

      unless products.present?
        csv << [row_hash[:hbx_enrollment_id], row_hash[:hios_id], enrollment.aasm_state, enrollment&.subscriber&.person.hbx_id, enrollment&.subscriber&.person.full_name, enrollment.coverage_kind, "No product present for the enrollment effective year"]
        next
      end

      if products.count > 1
        csv << [row_hash[:hbx_enrollment_id], row_hash[:hios_id], enrollment.aasm_state, enrollment&.subscriber&.person.hbx_id, enrollment&.subscriber&.person.full_name, enrollment.coverage_kind, "Multiple products present for the enrollment effective year"]
        next
      end

      if is_employer_sponsored_product(sponsored_product_ids, products) && is_different_effective_on(enrollment_effective_year, enrollment_product_year)
        enrollment.update_attributes!(product_id: products.first.id)
        puts "Hbx id #{person_hbx_id} - assigned enrollment with correct product for enrollment #{enrollment.hbx_id} "
        next
      end

      if !is_different_effective_on(enrollment_effective_year, enrollment_product_year) && benefit_packages.present?
        benefit_package =  if benefit_packages.count > 1
                             enrollment.sponsored_benefit.benefit_package
                           else
                             benefit_packages.first
                           end
        sponsored_benefit = benefit_package.sponsored_benefit_for(enrollment.coverage_kind.to_sym)
        enrollment.update_attributes!(sponsored_benefit_package_id: benefit_package.id, sponsored_benefit_id: sponsored_benefit.id, rating_area_id: benefit_package.recorded_rating_area.id, benefit_sponsorship_id: benefit_package.benefit_sponsorship.id)
        puts "Hbx id #{person_hbx_id}  - assigned enrollment with correct sponsored benefit for enrollment #{enrollment.hbx_id}"
      else
        csv << [row_hash[:hbx_enrollment_id], row_hash[:hios_id], enrollment.aasm_state, enrollment&.subscriber&.person.hbx_id, enrollment&.subscriber&.person.full_name, enrollment.coverage_kind, "No benefit packages present"]
      end
    end
  rescue Exception => e
    puts "Unable to open file #{e}" unless Rails.env.test?
  end
end

def is_fehb_employer?(profile)
  profile._type.match(/.*FehbEmployerProfile$/) if profile.present?
end

def is_employer_sponsored_product(product_ids, products)
  product_ids.include?(BSON::ObjectId.from_string(products.first.id))
end

def is_different_effective_on(enrollment_year, product_year)
  enrollment_year != product_year
end

begin
  CSV.open(report_name, "w", force_quotes: true) do |csv|
    csv << field_names
    process_enrollments(file_name, csv)
  end
rescue Exception => e
  puts "Unable to open file #{e}" unless Rails.env.test?
end

