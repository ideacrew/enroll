require 'csv'

namespace :reports do

  desc "Employer plan year application status by effective date"
  task :shop_monthly_enrollments => :environment do

    effective_on = TimeKeeper.date_of_record.next_month.beginning_of_month

    field_names  = ['Employer Name', 'Employer FEIN', 'Initial/Renewing', 'Enrollment Group ID']
    CSV.open("#{Rails.root}/public/shop_monthly_enrollments_#{effective_on.strftime('%m_%d_%Y')}.csv", "w") do |csv|
      csv << field_names

      Organization.where(:"employer_profile.plan_years" => { :$elemMatch => {:start_on => effective_on, :aasm_state => 'enrolled'} }, :"employer_profile.aasm_state".in => ['binder_paid']).each do |org|
        employer_profile =  org.employer_profile
        query_results = Queries::NamedPolicyQueries.shop_monthly_enrollments([employer_profile.fein], effective_on)
        query_results.each do |hbx_enrollment_id|
          csv << [employer_profile.legal_name, employer_profile.fein, 'Initial', hbx_enrollment_id]
        end
      end

      Organization.where(:"employer_profile.plan_years" => { :$elemMatch => {:start_on => effective_on.prev_year, :aasm_state => 'active'}}).each do |org|
        employer_profile = org.employer_profile
        if employer_profile.is_renewal_transmission_eligible?
          query_results = Queries::NamedPolicyQueries.shop_monthly_enrollments([employer_profile.fein], effective_on)
          query_results.each do |hbx_enrollment_id|
            csv << [employer_profile.legal_name, employer_profile.fein, 'Renewal', hbx_enrollment_id]
          end
        end
      end
    end
  end
end