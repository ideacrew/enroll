# frozen_string_literal: true

require 'csv'

field_names = %w[
                 person_hbx_id
                 person_full_name
                 enrollment_hbx_id
                 enrollment_created_at
                 enrollment_updated_at
                 enrollment_coverage_start_on
                 enrollment_state
                 enrollment_reference_plan_hios
                 enrollment_reference_plan_title
                 enrollment_total_employee_premium]

report_name = "#{Rails.root}/58832_employees_report_#{Time.now.strftime('%Y%m%d%H%M')}.csv"

enrollments = HbxEnrollment.where(:effective_on.gte => Date.new(2019, 7, 30),
                                  :$or => [
                                    {:$and => [
                                      {:created_at.gte => Date.new(2019, 9, 30)},
                                      {:created_at.lte => Date.new(2019, 10, 5)}

                                    ]},
                                    {:$and => [
                                      {:updated_at.gte => Date.new(2019, 9, 30)},
                                      {:updated_at.lte => Date.new(2019, 10, 5)}
                                    ]}
                                  ],
                                  :aasm_state.nin => %w(coverage_canceled shopping coverage_expired),
                                  coverage_kind: 'health',
                                  :kind.nin => ["individual"]
)

CSV.open(report_name, 'w', force_quotes: true) do |csv|
  csv << field_names

  array_hios_id = ["86052DC0440010-01", "86052DC0440011-01", "86052DC0440012-01", "86052DC0440013-01", "86052DC0440014-01", "86052DC0440015-01", "86052DC0440017-01", "86052DC0440018-01", "86052DC0440019-01", "86052DC0440020-01", "86052DC0440021-01", "86052DC0440022-01", "86052DC0440023-01", "86052DC0440024-01", "86052DC0440025-01", "86052DC0440026-01", "86052DC0460009-01", "86052DC0460010-01", "86052DC0460011-01", "86052DC0460012-01", "86052DC0460013-01", "86052DC0460014-01", "86052DC0460015-01", "86052DC0460016-01", "86052DC0460018-01", "86052DC0460019-01", "86052DC0460020-01", "86052DC0460021-01", "86052DC0460022-01", "86052DC0460023-01", "86052DC0460024-01", "86052DC0480007-01", "86052DC0480008-01", "86052DC0480009-01", "86052DC0480010-01", "86052DC0480011-01", "86052DC0480013-01", "86052DC0480014-01", "86052DC0500009-01", "86052DC0500010-01", "86052DC0500011-01", "86052DC0500012-01", "86052DC0500014-01", "86052DC0500015-01", "86052DC0500016-01", "86052DC0500017-01", "86052DC0500018-01", "86052DC0580001-01"]

  puts "Total enrollments: #{enrollments.count}"

  enrollments.each do |en|

    next unless en.product
    next unless array_hios_id.include?(en.product.hios_id)

    begin
      # puts "#{en.subscriber.person.hbx_id}; #{en.subscriber.person.full_name} ; #{en.hbx_id}; #{en.created_at};#{en.updated_at};#{en.effective_on}; #{en.aasm_state};#{en.product.hios_id}; #{en.product.title};#{en.total_premium};#{en.employer_profile.legal_name};#{en.sponsored_benefit_package.benefit_application.effective_period}; #{en.sponsored_benefit_package.benefit_application.aasm_state}"

      csv << [
          en.subscriber.person.hbx_id,
          en.subscriber.person.full_name,
          en.hbx_id,
          en.created_at,
          en.updated_at,
          en.effective_on,
          en.aasm_state,
          en.product.hios_id,
          en.product.title,
          en.total_premium,
          en.employer_profile.legal_name,
          en.sponsored_benefit_package.benefit_application.effective_period,
          en.sponsored_benefit_package.benefit_application.aasm_state
      ]
    rescue => e
      puts "Employer Legal Name #{benefit_sponsor.legal_name} , ERROR: #{e}"
    end
  end
end

