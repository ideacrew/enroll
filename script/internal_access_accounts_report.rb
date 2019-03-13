require 'csv'

def timestamp
  Time.now.strftime('%m_%d_%Y_at_%H_%M')
end

def all_hbx_staff_role
  Person.exists(hbx_staff_role: true)
end

def fields_for_record
  %w(user_id last_name first_name hbx_staff_sub_role created_at last_log_in deactived_on status)
end

def hbx_staff_people_active
  Person.where(:hbx_staff_role =>{"$exists"=>true}, "hbx_staff_role.is_active" => true)
end

def hbx_staff_people_inactive
  Person.where(:hbx_staff_role =>{"$exists"=>true}, "hbx_staff_role.is_active" => false)
end

def hbx_role(person)
  person.hbx_staff_role
end

def last_login(person)
  SessionIdHistory.for_user(user_id: person.user_id).order('created_at DESC').first.created_at
end

def role_status(person)
  hbx_role(person).is_active? ? "active" : "inactive"
end

def build_record(person)
  [person.user.id, person.last_name, person.first_name, hbx_role(person).subrole, hbx_role(person).created_at, last_login(person), "", role_status(person)]
end

CSV.open("internal_access_accounts_report_#{timestamp}.csv","w") do |csv|
  empty_sub = fields_for_record.drop(1).map{''}
  csv << ["Report generated #{timestamp}"] + empty_sub
  csv << ["There are #{all_hbx_staff_role.count} people who have a hbx_staff_role"] + empty_sub
  csv << ["Genereating report ********************"] + empty_sub
  csv << ["Deactivated Admins ********************"] + empty_sub
  csv << fields_for_record
  hbx_staff_people_inactive.each do |person|
    csv << build_record(person)
  end
  csv << [''] + empty_sub
  csv << ["Deactivated Admins ********************"] + empty_sub
  hbx_staff_people_active.each do |person|
    csv << build_record(person)
  end
end