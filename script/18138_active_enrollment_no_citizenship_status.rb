require "csv"
CSV.open("new_data.csv", "wb") do |csv_out|
  csv_out << ["family.id", "policy.id", "policy.subscriber.coverage_start_on", "policy.aasm_state", "policy.plan.coverage_kind", "policy.plan.metal_level", "policy.plan.name", "policy.subscriber.person.hbx_id", "policy.subscriber.person.is_incarcerated", "policy.subscriber.person.citizen_status", "policy.subscriber.person.is_dc_resident?", "is_dependent", "has_active_employee_role?", "has_active_consumer_role?"]
  CSV.foreach("no_citizen_status_enrolled.csv",{:headers=>:first_row}) do |row, i|
    next if i == 0
    hbx_id = row["policy.subscriber.person.hbx_id"]
    person = Person.where(:hbx_id => hbx_id).first
    row << person.has_active_employee_role?
    row << person.has_active_consumer_role?
    csv_out << row
  end
end