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

report_name = "#{Rails.root}/58832_employers_report_#{Time.now.strftime('%Y%m%d%H%M')}.csv"

CSV.open(report_name, 'w', force_quotes: true) do |csv|
  csv << field_names

  estimator = ::BenefitSponsors::Services::SponsoredBenefitCostEstimationService.new

  array_hios_id = ["86052DC0440010-01", "86052DC0440011-01", "86052DC0440012-01", "86052DC0440013-01", "86052DC0440014-01", "86052DC0440015-01", "86052DC0440017-01", "86052DC0440018-01", "86052DC0440019-01", "86052DC0440020-01", "86052DC0440021-01", "86052DC0440022-01", "86052DC0440023-01", "86052DC0440024-01", "86052DC0440025-01", "86052DC0440026-01", "86052DC0460009-01", "86052DC0460010-01", "86052DC0460011-01", "86052DC0460012-01", "86052DC0460013-01", "86052DC0460014-01", "86052DC0460015-01", "86052DC0460016-01", "86052DC0460018-01", "86052DC0460019-01", "86052DC0460020-01", "86052DC0460021-01", "86052DC0460022-01", "86052DC0460023-01", "86052DC0460024-01", "86052DC0480007-01", "86052DC0480008-01", "86052DC0480009-01", "86052DC0480010-01", "86052DC0480011-01", "86052DC0480013-01", "86052DC0480014-01", "86052DC0500009-01", "86052DC0500010-01", "86052DC0500011-01", "86052DC0500012-01", "86052DC0500014-01", "86052DC0500015-01", "86052DC0500016-01", "86052DC0500017-01", "86052DC0500018-01", "86052DC0580001-01"]

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
               {:created_at.lte => Date.new(2019, 10, 8)}

             ]},
             {:$and => [
               {:updated_at.gte => Date.new(2019, 9, 30)},
               {:updated_at.lte => Date.new(2019, 10, 8)}
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
          next unless array_hios_id.include?(sp.reference_product.hios_id)

          begin
            estimate = estimator.calculate_estimates_for_benefit_display(sp)
            sp_count += 1
            # puts "#{benefit_sponsor.legal_name}; #{ba.aasm_state}; benefit_package_#{bp_count};sponsored_benefit_#{sp_count}; #{ba.effective_period} ; #{ba.created_at}; #{ba.updated_at}; #{sp.reference_product.hios_id}; #{sp.reference_product.title};#{estimate[:estimated_sponsor_exposure]}"

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