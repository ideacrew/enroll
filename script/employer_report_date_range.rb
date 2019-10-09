# frozen_string_literal: true

require 'csv'

field_names = %w[legal_name
                 py_state
                 benefit_packages
                 sponsored_benefits
                 py_effective_period
                 py_created_at
                 py_updated_at
                 py_reference_plan_hios
                 py_reference_plan_title
                 py_total_employer_cost]

report_name = "#{Rails.root}/58832_employers_report_#{TimeKeeper.date_of_record}.csv"

benefitsponsors = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(
  {
    :benefit_applications.exists => true,
    :'benefit_applications.aasm_state'.nin => [:canceled],
    :benefit_applications =>
      {:$elemMatch =>
         {
           :$or => [
             {:$and => [
               {:created_at.gte => Date.new(2019, 9, 30)},
               {:created_at.lte => Date.new(2019, 10, 4)}

             ]},
             {:$and => [
               {:updated_at.gte => Date.new(2019, 9, 30)},
               {:updated_at.lte => Date.new(2019, 10, 4)}
             ]}
           ]
         }}
  }
)


CSV.open(report_name, 'w', force_quotes: true) do |csv|
  csv << field_names

  estimator = ::BenefitSponsors::Services::SponsoredBenefitCostEstimationService.new

  benefitsponsors = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(
    {
      :benefit_applications.exists => true,
      :'benefit_applications.aasm_state'.nin => [:canceled],
      :benefit_applications =>
        {:$elemMatch =>
         {
           :$or => [
             {:$and => [
               {:created_at.gte => Date.new(2019, 9, 30)},
               {:created_at.lte => Date.new(2019, 10, 4)}

             ]},
             {:$and => [
               {:updated_at.gte => Date.new(2019, 9, 30)},
               {:updated_at.lte => Date.new(2019, 10, 4)}
             ]}
           ]
         }}
    }
  )

  puts "Total Employers: #{benefitsponsors.count}"

  benefitsponsors.each do |benefit_sponsor|

    ba_2019 = benefit_sponsor.benefit_applications.where(:'effective_period.min'.gte => Date.new(2019, 9, 1))
    bp_count = 0
    ba_2019.each do |ba|
      ba.benefit_packages.each do |bp|
        bp_count += 1
        sp_count = 0
        bp.sponsored_benefits.each do |sp|
          begin
            estimate = estimator.calculate_estimates_for_benefit_display(sp)
            sp_count += 1
            csv << [benefit_sponsor.legal_name,
                    ba.aasm_state,
                    "benefit_package_#{bp_count}",
                    "sponsored_benefit_#{sp_count}",
                    ba.effective_period,
                    ba.created_at,
                    ba.updated_at,
                    sp.reference_product.hios_id,
                    sp.reference_product.title,
                    estimate[:estimated_sponsor_exposure]]
          rescue => e
            puts "Employer Legal Name #{benefit_sponsor.legal_name} , ERROR: #{e}"
          end
        end
      end
    end
  end
end