namespace :renewal_state_change do
  desc "Correct the IVL users enrollment aasm state"
  task ivl_users: :environment do
    puts "Found #{kollection.count} enrollments requires state change" unless Rails.env.test?
    upload_and_transition_state
    puts "Updated the state for set of IVL users and find those ivl users on ivl_state_changed_users.csv file" unless Rails.env.test?
  end

  def kollection
    @kollection ||= HbxEnrollment.where(kind: "individual", aasm_state: "renewing_coverage_selected")
  end

  def upload_and_transition_state
    headers = %w[first_name last_name primary_person_hbx_id enrollment_policy_id coverage_kind]
    file_name = File.expand_path("#{Rails.root}/public/ivl_state_changed_users.csv")

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << headers
      kollection.each do |enrollment|
        enrollment.begin_coverage!
        primary_person = enrollment.family.primary_person
        csv << [primary_person.send(:first_name), primary_person.send(:last_name), primary_person.send(:hbx_id), enrollment.hbx_id, enrollment.coverage_kind]
      end
    end
  end
end
