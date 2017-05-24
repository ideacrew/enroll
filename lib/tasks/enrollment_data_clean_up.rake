# This rake task is to generate a list of enrollments satisfying the following scenario:
# Given a user has an active enrollment E1 with effective date X
# When the user purchases a new enrollment E2 with effective date Y
# And E2 is the same plan year
# And E2 is the same market type
# And E2 has the same subscriber
# E2 effective date > E1 effective date > E2 submitted on date.
# Then E1 is Canceled


require 'csv'
namespace :reports do
  desc "Report of enrollments placed in to the cancel state erroneously"
  task :list_of_enrollments_in_cancel_state_erroneously => :environment do
    file_name = "#{Rails.root}/enrollments_in_cancel_state_erroneously.csv"
    field_names  = ["HBX Subscriber ID",
                    "Cancel_enrollment_hbx_id",
                    "Cancel_enrollment_effective_date",
                    "Cancel_enrollment_market_type",
                    "Reference_enrollment_hbx_id"
                    ]
    CSV.open(file_name, "w") do |csv|
      csv << field_names
      families=Family.where(:"households.hbx_enrollments.aasm_state".in => HbxEnrollment::CANCELED_STATUSES)
      families.each do |family|
        enrollments=family.active_household.hbx_enrollments
        break unless enrollments.size >= 2
        canceled_enrollments=enrollments.where(aasm_state:"coverage_canceled")
        break unless canceled_enrollments.size >= 1
        other_enrollments = enrollments - canceled_enrollments
        break unless other_enrollments.size > 0

        canceled_enrollments.each do |canceled_enrollment|
          other_enrollments.each do |enrollment|
            break unless canceled_enrollment.kind == enrollment.kind
            break unless canceled_enrollment.subscriber && enrollment.subscriber
            cancel_member=canceled_enrollment.subscriber
            reference_member=enrollment.subscriber
            break unless cancel_member.person.id == reference_member.person.id
            break unless canceled_enrollment.effective_on && enrollment.effective_on && enrollment.submitted_at
            cancel_effective=canceled_enrollment.effective_on
            reference_effective=enrollment.effective_on
            reference_submitted=enrollment.submitted_at
            break unless cancel_effective > reference_submitted && cancel_effective < reference_effective
            if canceled_enrollment.kind == "individual"
              return unless canceled_enrollment.effective_on.year == enrollment.effective_on.year
              csv << [cancel_member.person.hbx_id,
                      canceled_enrollment.hbx_id,
                      canceled_enrollment.effective_on,
                      canceled_enrollment.kind,
                      enrollment.hbx_id
                      ]

            elsif canceled_enrollment.kind == "employer_sponsored"
              return unless canceled_enrollment.benefit_group.plan_year == enrollment.benefit_group.plan_year
              csv << [cancel_member.person.hbx_id,
                      canceled_enrollment.hbx_id,
                      canceled_enrollment.effective_on,
                      canceled_enrollment.kind,
                      enrollment.hbx_id
                      ]
              end
          end
        end
      end
    end
  end
end



