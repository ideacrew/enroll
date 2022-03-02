# frozen_string_literal: true

# rake reports:enrollment_service_area_change

require 'csv'

namespace :reports do
  desc "Enrolled families with a different service area than enrollment"
  task :enrollment_service_area_change => :environment do

    field_names  = %w[
      hbx_id
      primary_phone
      primary_email
      enrollment_hbx_id
      plan_name
      plan_hios_id
      enrollment_rating_area
      address
      address_rating_area
      address_changed_on
      product_offered_in_service_area
      premium
    ]

    file_name = "#{Rails.root}/enrollment_service_area_change_#{TimeKeeper.date_of_record.strftime('%Y-%m-%d')}.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      enrollments = HbxEnrollment.all.individual_market.where(:aasm_state.in => HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES, :rating_area_id.ne => nil)

      enrollments.each do |enrollment|

        enrollment_rating_area = enrollment.rating_area.exchange_provided_code
        rating_address = (enrollment.consumer_role || enrollment.resident_role).rating_address

        address_rating_area = ::BenefitMarkets::Locations::RatingArea.rating_area_for(
          rating_address,
          during: enrollment.effective_on
        ).exchange_provided_code

        service_areas = ::BenefitMarkets::Locations::ServiceArea.service_areas_for(
          rating_address,
          during: enrollment.effective_on
        ).map(&:id)

        person = enrollment.family.primary_person
        product = enrollment.product
        product_offered_in_service_area = service_areas.include?(product.service_area_id)

        if (enrollment_rating_area != address_rating_area) || !product_offered_in_service_area
          csv << [
            person.hbx_id,
            person.work_phone_or_best,
            person.work_email_or_best,
            enrollment.hbx_id,
            product.title,
            product.hios_id,
            enrollment_rating_area,
            rating_address.to_s,
            address_rating_area,
            rating_address.updated_at,
            product_offered_in_service_area,
            enrollment.total_premium
          ]
        end
      rescue StandardError => e
        puts "Error while determining for #{enrollment.hbx_id} with error - #{e}"
      end

      puts "Succesfully verified #{enrollments.size} enrollments"
    end
  end
end
