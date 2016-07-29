# OLD STATES >>
    # state :verifications_pending, initial: true
    # state :verifications_outstanding
    # state :fully_verified
# >> old states


# NEW STATES
    # state :unverified, initial: true
    # state :ssa_pending
    # state :dhs_pending
    # state :verification_outstanding
    # state :fully_verified
    # state :verification_period_ended
# >> new states

# case #  |  "LPD Status"  | "LPD Auth" | "native" | "has ssn" | "consumer role status" | "lpd status"  | "ssn status"
# -----   |  ------------------------------------------------------------------------------------------------------------
# case 1  |  "outstanding" | "ssa"      |  "true"  | "true"    | "outstanding"          | "outstanding" | "outstanding"
# case 2  |  "outstanding" | "ssa"      |  "true"  | "false"   | "outstanding"          | "outstanding" | "outstanding"
# case 3  |  "outstanding" | "dhs"      |  "false" | "false"   | "outstanding"          | "outstanding" | "outstanding"
# case 4  |  "pending"     | "ssa"      |  "true"  | "true"    | "pending, retrigger"   | "pending"     | "pending"
# case 5  |  "pending"     | "dhs"      |  "false" | "false"   | "pending, retrigger"   | "pending"     | "n/a"
# case 6  |  "valid"       | "ssa"      |  "true"  | "true"    | "valid"                | "valid"       | "valid"
# case 7  |  "pending"     | "ssa"      |  "true"  | "false"   | "outstanding"          | "outstanding" | "outstanding"
# case 8  |  "valid"       | "dhs"      |  "false" | "false"   | "valid"                | "valid"       | "n/a"
# case 9  |  "_"           | "curam"    |  "_"     | "true"    | "valid"                | "valid"       | "valid"
# case 10 |  "_"           | "curam"    |  "_"     | "false"   | "valid"                | "valid"       | "n/a"
# case 11 |  "_"           | "dhs"      |  "false" | "true"    | "pending, retrigger"   | "pending"     | "pending"


# outstanding, native, ssn  | count: 401
def get_case_1_people
  Person.where('consumer_role' => {'$exists' => true},
               'consumer_role.lawful_presence_determination.aasm_state' => 'verification_outstanding',
               'consumer_role.lawful_presence_determination.citizen_status' => 'us_citizen',
               'encrypted_ssn' => {'$exists' => true})

end

# outstanding, native, NO ssn  | count: 209
def get_case_2_people
  Person.where('consumer_role' => {'$exists' => true},
               'consumer_role.lawful_presence_determination.aasm_state' => 'verification_outstanding',
               'consumer_role.lawful_presence_determination.citizen_status' => 'us_citizen',
               'encrypted_ssn' => {'$exists' => false})
end

# outstanding, NON native, NO ssn  | count: 61
def get_case_3_people
  Person.where('consumer_role' => {'$exists' => true},
               'consumer_role.lawful_presence_determination.aasm_state' => 'verification_outstanding',
               'consumer_role.lawful_presence_determination.citizen_status' => {'$ne' => 'us_citizen'},
               'encrypted_ssn' => {'$exists' => false})
end

# pending, native, ssn  | count: 8785
def get_case_4_people
  Person.where('consumer_role' => {'$exists' => true},
               'consumer_role.lawful_presence_determination.aasm_state' => 'verification_pending',
               'consumer_role.lawful_presence_determination.citizen_status' => 'us_citizen',
               'encrypted_ssn' => {'$exists' => true})
end

# pending, NO native, NO ssn   | count: 1091
def get_case_5_people
  Person.where('consumer_role' => {'$exists' => true},
               'consumer_role.lawful_presence_determination.aasm_state' => 'verification_pending',
               'consumer_role.lawful_presence_determination.citizen_status' => {'$ne' => 'us_citizen'},
               'encrypted_ssn' => {'$exists' => false})
end

# verified, native, ssn    | count: 27891
def get_case_6_people
  Person.where('consumer_role' => {'$exists' => true},
               'consumer_role.lawful_presence_determination.aasm_state' => 'verification_successful',
               'consumer_role.lawful_presence_determination.citizen_status' => 'us_citizen',
               'encrypted_ssn' => {'$exists' => true})
end

# pending, native, NO ssn  | count: 1084
def get_case_7_people
  Person.where('consumer_role' => {'$exists' => true},
               'consumer_role.lawful_presence_determination.aasm_state' => 'verification_pending',
               'consumer_role.lawful_presence_determination.citizen_status' => 'us_citizen',
               'encrypted_ssn' => {'$exists' => false})
end

# verified, NO native, NO ssn  | count: 441
def get_case_8_people
  Person.where('consumer_role' => {'$exists' => true},
               'consumer_role.lawful_presence_determination.aasm_state' => 'verification_successful',
               'consumer_role.lawful_presence_determination.citizen_status' => {'$ne' => 'us_citizen'},
               'encrypted_ssn' => {'$exists' => false})
end

#Curam, ssn   | count: 39338
def get_case_9_people
  Person.where('consumer_role' => {'$exists' => true},
               'consumer_role.lawful_presence_determination.vlp_authority' => 'curam',
               'encrypted_ssn' => {'$exists' => true})
end

#Curam, NO ssn   | count:  1575
def get_case_10_people
  Person.where('consumer_role' => {'$exists' => true},
               'consumer_role.lawful_presence_determination.vlp_authority' => 'curam',
               'encrypted_ssn' => {'$exists' => false})
end

#NON native, ssn   | count: 62955
def get_case_11_people
  Person.where('consumer_role' => {'$exists' => true},
               'consumer_role.lawful_presence_determination.citizen_status' => {'$ne' => 'us_citizen'},
               'encrypted_ssn' => {'$exists' => true})
end



# ---------DATA MIGRATION-----------------

def consumer_to_outstanding(person)
  person.consumer_role.aasm_state = "verification_outstanding"
end

def consumer_to_unverified(person)
  person.consumer_role.aasm_state = "unverified"
end

def retrigger(person)
  consumer_to_unverified(person)
  person.consumer_role.invoke_verification!
end

def consumer_to_verified(person)
  person.consumer_role.aasm_state = "fully_verified"
end

def lp_to_outstanding(person)
  person.consumer_role.lawful_presence_determination.aasm_state = "verification_outstanding"
end

def lp_to_pending(person)
  person.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
end

def lp_to_verified(person)
  person.consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
end

def ssn_to_outstanding(person)
  person.consumer_role.ssn_validation = "outstanding"
end

def ssn_to_pending(person)
  person.consumer_role.ssn_validation = "pending"
end

def ssn_to_verified(person)
  person.consumer_role.ssn_validation = "valid"
end

def ssn_to_na(person)
  person.consumer_role.ssn_validation = "na"
end

def move_all_to_outstanding(person)
  consumer_to_outstanding(person)
  lp_to_outstanding(person)
  ssn_to_outstanding(person)
end

def move_all_to_pending(person)
  retrigger(person)
  lp_to_pending(person)
  ssn_to_pending(person)
end

#---- case migrations ----#

def migration_1
  puts "Start runnung #{__method__}..."
  people = get_case_1_people
  puts "#{people.count} records will be fixed."
  errors=0
  people.each do |person|
    begin
      move_all_to_outstanding(person)
      person.save!
    rescue => e
      errors+=1
      puts "data migration error for person: #{person.id}. Error: #{e.message}"
    end
  end
  if errors > 0
    puts "You have #{errors} errors for #{__method__}"
  else
    puts "No errors for #{__method__}"
  end
end

def migration_2
  puts "Start runnung #{__method__}..."
  people = get_case_2_people
  puts "#{people.count} records will be fixed."
  errors=0
  people.each do |person|
    begin
      move_all_to_outstanding(person)
      person.save!
    rescue => e
      errors+=1
      puts "data migration error for person: #{person.id}. Error: #{e.message}"
    end
  end
  if errors > 0
    puts "You have #{errors} errors for #{__method__}"
  else
    puts "No errors for #{__method__}"
  end
end

def migration_3
  puts "Start runnung #{__method__}..."
  people = get_case_3_people
  puts "#{people.count} records will be fixed."
  errors=0
  people.each do |person|
    begin
      move_all_to_outstanding(person)
      person.save!
    rescue => e
      errors+=1
      puts "data migration error for person: #{person.id}. Error: #{e.message}"
    end
  end
  if errors > 0
    puts "You have #{errors} errors for #{__method__}"
  else
    puts "No errors for #{__method__}"
  end
end

def migration_4
  puts "Start runnung #{__method__}..."
  people = get_case_4_people
  puts "#{people.count} records will be fixed."
  errors=0
  people.each do |person|
    begin
      move_all_to_pending(person)
      person.save!
    rescue => e
      errors+=1
      puts "data migration error for person: #{person.id}. Error: #{e.message}"
    end
  end
  if errors > 0
    puts "You have #{errors} errors for #{__method__}"
  else
    puts "No errors for #{__method__}"
  end
end

def migration_5
  puts "Start runnung #{__method__}..."
  people = get_case_5_people
  puts "#{people.count} records will be fixed."
  errors=0
  people.each do |person|
    begin
      retrigger(person)
      lp_to_pending(person)
      ssn_to_na(person)
      person.save!
    rescue => e
      errors+=1
      puts "data migration error for person: #{person.id}. Error: #{e.message}"
    end
  end
  if errors > 0
    puts "You have #{errors} errors for #{__method__}"
  else
    puts "No errors for #{__method__}"
  end
end

def migration_6
  puts "Start runnung #{__method__}..."
  people = get_case_6_people
  puts "#{people.count} records will be fixed."
  errors=0
  people.each do |person|
    begin
      consumer_to_verified(person)
      lp_to_verified(person)
      ssn_to_verified(person)
      person.save!
    rescue => e
      errors+=1
      puts "data migration error for person: #{person.id}. Error: #{e.message}"
    end
  end
  if errors > 0
    puts "You have #{errors} errors for #{__method__}"
  else
    puts "No errors for #{__method__}"
  end
end

def migration_7
  puts "Start runnung #{__method__}..."
  people = get_case_7_people
  puts "#{people.count} records will be fixed."
  errors=0
  people.each do |person|
    begin
      move_all_to_outstanding(person)
      person.save!
    rescue => e
      errors+=1
      puts "data migration error for person: #{person.id}. Error: #{e.message}"
    end
  end
  if errors > 0
    puts "You have #{errors} errors for #{__method__}"
  else
    puts "No errors for #{__method__}"
  end
end

def migration_8
  puts "Start runnung #{__method__}..."
  people = get_case_8_people
  puts "#{people.count} records will be fixed."
  errors=0
  people.each do |person|
    begin
      consumer_to_verified(person)
      lp_to_verified(person)
      ssn_to_na(person)
      person.save!
    rescue => e
      errors+=1
      puts "data migration error for person: #{person.id}. Error: #{e.message}"
    end
  end
  if errors > 0
    puts "You have #{errors} errors for #{__method__}"
  else
    puts "No errors for #{__method__}"
  end
end

def migration_9
  puts "Start runnung #{__method__}..."
  people = get_case_9_people
  puts "#{people.count} records will be fixed."
  errors=0
  people.each do |person|
    begin
      consumer_to_verified(person)
      lp_to_verified(person)
      ssn_to_verified(person)
      person.save!
    rescue => e
      errors+=1
      puts "data migration error for person: #{person.id}. Error: #{e.message}"
    end
  end
  if errors > 0
    puts "You have #{errors} errors for #{__method__}"
  else
    puts "No errors for #{__method__}"
  end
end

def migration_10
  puts "Start runnung #{__method__}..."
  people = get_case_10_people
  puts "#{people.count} records will be fixed."
  errors=0
  people.each do |person|
    begin
      consumer_to_verified(person)
      lp_to_verified(person)
      ssn_to_na(person)
      person.save!
    rescue => e
      errors+=1
      puts "data migration error for person: #{person.id}. Error: #{e.message}"
    end
  end
  if errors > 0
    puts "You have #{errors} errors for #{__method__}"
  else
    puts "No errors for #{__method__}"
  end
end

def migration_11
  puts "Start runnung #{__method__}..."
  people = get_case_11_people
  puts "#{people.count} records will be fixed."
  errors=0
  people.each do |person|
    begin
      move_all_to_pending(person)
      person.save!
    rescue => e
      errors+=1
      puts "data migration error for person: #{person.id}. Error: #{e.message}"
    end
  end
  if errors > 0
    puts "You have #{errors} errors for #{__method__}"
  else
    puts "No errors for #{__method__}"
  end
end

def init_migration!
  migration_1
  migration_2
  migration_3
  migration_4
  migration_5
  migration_6
  migration_7
  migration_8
  migration_9
  migration_10
  migration_11
end

init_migration!


