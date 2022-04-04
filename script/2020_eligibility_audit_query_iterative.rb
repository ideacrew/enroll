require 'delegate'

Caches::PlanDetails.drop_cache_to_free_ram!
MallocTrim.trim

ITERATION_RUN = 4

AUDIT_START_DATE = Date.new(2019,10,1)
AUDIT_END_DATE = Date.new(2020,10,1)
STDOUT.puts "Standard caching complete."
STDOUT.flush

PROC_COUNT = 10

STDERR.puts "TESTING STANDARD ERROR REDIRECTION"
STDERR.flush

RECORDS_AT_ISSUE = [
]

RECORDS_AT_ISSUE.each do |rec_no|
  puts "Excluding potentially corrupt record: #{rec_no}"
end
STDOUT.flush

h_packages = IvlEligibilityAudits::AuditQueryCache.benefit_packages_for(2020)
puts "Health Benefit Packages located."
STDOUT.flush

def load_person_id_list(iteration_number)
  list_file_text = File.read("2020_outstanding_people_iteration_#{iteration_number}.txt")
  list_file_text.split("\n").map(&:strip)
end

ivl_person_ids = load_person_id_list(ITERATION_RUN)
STDOUT.puts "Counted #{ivl_person_ids.count} people."
STDOUT.flush

families_of_interest = Family.where(
  {"family_members.person_id" => {"$in" => ivl_person_ids}}
)
STDOUT.puts "Counted #{families_of_interest.count} families."
STDOUT.flush

family_map = IvlEligibilityAudits::AuditQueryCache.generate_family_map_for(ivl_person_ids)

# So what we need here is: family_membership * person_record * version_numbers_for_person
person_id_count = ivl_person_ids.length
STDOUT.puts person_id_count.inspect
STDOUT.puts families_of_interest.count
STDOUT.flush

def relationship_for(person, family, version_date)
  return "self" if (person.id == family.primary_applicant.person_id)
  fm_person = family.primary_applicant.person_version_for(version_date)
  return "unrelated" unless fm_person
  fm_person.person_relationships.select { |r| r.relative_id.to_s == person.id.to_s}.first.try(:kind) || "unrelated"
end

def version_in_window?(updated_at)
  (updated_at >= AUDIT_START_DATE) && (updated_at < AUDIT_END_DATE)
end

def calc_eligibility_for(cr, family, benefit_packages, ed)
  effective_date = (ed < Date.new(2020,1,1)) ? Date.new(2020,1,1) : ed.to_date
  all_eligibilities = benefit_packages.map do |hbp|
    [
      hbp,
      InsuredEligibleForBenefitRule.new(cr, hbp, {new_effective_on: effective_date, family: family, version_date: ed, market_kind: "individual"}).satisfied?
    ]
  end
  eligible_value = all_eligibilities.any? do |ae|
    ae.last.first
  end
  eligibility_error_lookups = all_eligibilities.reject do |ae|
    ae.last.first
  end
  eligibility_errors = eligibility_error_lookups.map do |eel|
    {
      package: eel.first.title,
      errors: eel.last.last
    }.to_json
  end
  [eligible_value, eligibility_errors.join("\n")]
end

def home_address_for(person)
  home_address = person.home_address
  return([nil, nil, nil, nil, nil]) if home_address.blank?
  [home_address.address_1, home_address.address_2,
   home_address.city, home_address.state, home_address.zip]
end

def mailing_address_for(person)
  return([nil, nil, nil, nil, nil]) unless person.has_mailing_address?
  home_address = person.mailing_address
  [home_address.address_1, home_address.address_2,
   home_address.city, home_address.state, home_address.zip]
end

# Discard cases where we don't have a home OR mailing address for the primary
# We block them earlier in the process
def primary_has_address?(person, person_version, family)
   # If I'm the primary, do I have an address on this version?
  if (person.id == family.primary_applicant.person_id)
    !(person_version.home_address.blank? && person_version.mailing_address.blank?)
  else
    !(family.primary_applicant.person.home_address.blank? && family.primary_applicant.person.mailing_address.blank?)
  end
end
# Exclude individuals who have not even completed the application.
# They are blocked by the UI rules far earlier in the process.
def primary_answered_data?(person, person_version, family)
  if (person.id == family.primary_applicant.person_id)
    primary_person = person_version
    cr = primary_person.consumer_role
    return false if cr.blank?
    lpd = cr.lawful_presence_determination
    return false if lpd.blank?
    !(lpd.citizen_status.blank? || (primary_person.is_incarcerated == nil))
  else
    primary_person = family.primary_applicant.person
    cr = primary_person.consumer_role
    return false if cr.blank?
    lpd = cr.lawful_presence_determination
    return false if lpd.blank?
    !(lpd.citizen_status.blank? || (primary_person.is_incarcerated == nil))
  end
end

# Select only if curam is not the authorization authority
def not_authorized_by_curam?(person)
  cr = person.consumer_role
  return true if cr.blank?
  lpd = cr.lawful_presence_determination
  return true if lpd.blank?
  !(lpd.vlp_authority == "curam")
end

def auditable?(person_record, person_version, person_updated_at, family)
  version_in_window?(person_updated_at) &&
  primary_has_address?(person_record, person_version, family) &&
  primary_answered_data?(person_record, person_version, family) &&
  not_authorized_by_curam?(person_version)
end

def fork_kids(ivl_ids, f_map, hb_packages, exclusions, iteration_number)
  child_list = Array.new
  id_chunks = ivl_ids.in_groups(PROC_COUNT, false)
  (1..PROC_COUNT).to_a.each do |proc_index|
    child_ivl_ids = id_chunks[proc_index - 1]
    reader, writer = IO.pipe
    signalled, signaller = IO.pipe
    fork_result = Process.fork
    if fork_result.nil?
      signaller.close
      reader.close
      signal_chans, _ws, _es = IO.select([signalled])
      signal_chans.each do |sc|
        sc.read(1)
      end
      signalled.close
      STDERR.puts "Child #{Process.pid}: START SIGNAL RECIEVED"
      STDERR.flush
      run_audit_for_batch(proc_index, child_ivl_ids, writer, f_map, hb_packages, exclusions, iteration_number)
      writer.close
      exit 0
    else
      writer.close
      signalled.close
      STDOUT.puts "Launched child: #{proc_index}, pid: #{fork_result}"
      STDOUT.flush
      child_list << [fork_result, signaller, reader]
    end
  end
  child_list
end

def run_audit_for_batch(current_proc_index, ivl_people_ids, writer, person_family_map, health_benefit_packages, exclusions, iteration_number)
  keys_to_delete = person_family_map.keys - ivl_people_ids
  keys_to_delete.each do |k|
    person_family_map.delete(k)
  end
  GC.start
  MallocTrim.trim
  f = File.open("audit_log_iteration_#{iteration_number}_slice_#{current_proc_index}.log", 'w')
  f.puts "=== RECORD LIST BEGIN ==="
  ivl_people_ids.each do |ivl_p_id|
    f.puts ivl_p_id.to_s
  end
  f.puts "=== RECORD LIST END ==="
  begin
    ivl_people = IvlEligibilityAudits::EligibilityQueryCursor.new(ivl_people_ids, exclusions)
    CSV.open("audit_ivl_determinations_iteration_#{iteration_number}_slice_#{current_proc_index}.csv", "w") do |csv|
      csv << [
        "Family ID",
        "Hbx ID",
        "Last Name",
        "First Name",
        "Full Name",
        "Date of Birth",
        "Gender",
        "Application Date",
        "Primary Applicant",
        "Relationship",
        "Citizenship Status",
        "American Indian",
        "Incarceration",
        "Home Street 1",
        "Home Street 2",
        "Home City",
        "Home State",
        "Home Zip",
        "Mailing Street 1",
        "Mailing Street 2",
        "Mailing City",
        "Mailing State",
        "Mailing Zip",
        "No DC Address",
        "Residency Exemption Reason",
        "Is applying for coverage",
        "Resident Role",
        "Eligible",
        "Denial Reasons"
      ]
      ivl_people.each do |pers_record|
        f.puts "++++ PROCESSING RECORD: #{pers_record.id.to_s}"
        person_versions = Versioning::VersionCollection.new(pers_record)
        person_versions.each do |p_v|
          begin
            p_version = p_v.resolve_to_model
            person_updated_at = p_v.timestamp
            families = person_family_map[pers_record.id]
            # This "pers" variable will be the version that is appended to the CSV
            pers = p_version
            families.each do |fam|
              cr = pers.consumer_role
              if cr
                cr.person = p_version
                begin
                  if auditable?(pers_record, p_version, person_updated_at, fam)
                    eligible, eligibility_errors = calc_eligibility_for(cr, fam, health_benefit_packages, person_updated_at)
                    lpd = cr.lawful_presence_determination
                    if lpd
                      address_fields = home_address_for(pers)
                      mailing_address_fields = mailing_address_for(pers)
                      csv << ([
                        fam.id,
                        pers.hbx_id,
                        pers.last_name,
                        pers.first_name,
                        pers.full_name,
                        pers.dob,
                        pers.gender,
                        person_updated_at.strftime("%Y-%m-%d %H:%M:%S.%L"),
                        (pers_record.id == fam.primary_applicant.person_id),
                        relationship_for(pers_record, fam, person_updated_at),
                        lpd.citizen_status,
                        (lpd.citizen_status.nil? ? nil : (lpd.citizen_status == "indian_tribe_member")),
                        pers.is_incarcerated] +
                        address_fields +
                        mailing_address_fields +
                        [
                          pers.no_dc_address,
                          pers.no_dc_address ? pers.no_dc_address_reason : "",
                          cr.is_applying_coverage,
                          pers.resident_role.present?,
                          eligible,
                          eligible ? "" : eligibility_errors
                      ])
                    end
                  end          
                rescue Mongoid::Errors::DocumentNotFound => e
                  f.puts e.inspect
                  f.flush
                  puts e.inspect
                end
              end
            end
          rescue HistoryTrackerReversalError => htre
            f.puts "===== ERROR BEGIN ===="
            f.puts pers.inspect
            f.puts htre.inspect
            f.puts "===== ERROR END ===="
            f.flush
          end
        end
        f.puts "++++ PROCESSED RECORD: #{pers_record.id.to_s}"
        writer.write("+")
        person_family_map.delete(pers_record.id)
      end
    end
  ensure
    f.puts "===== REACHED END OF RECORDS ====="
    f.flush
    f.close
  end
end

reader_map = Hash.new

Signal.trap("CLD") do
  STDERR.puts "DEAD CHILD SIGNALLED"
  STDERR.flush
  child_pids = reader_map.keys.dup
  child_pids.each do |cpid|
    dead_child = Process.wait(cpid, Process::WNOHANG)
    if !dead_child.nil?
      STDERR.puts "Child died: #{dead_child}"
      STDERR.flush
      begin
        reader_map[dead_child].close
      rescue
        STDERR.puts "Child #{dead_child} reader already closed."
        STDERR.flush
      end
      reader_map.delete(dead_child)
    end
  end
end

STDOUT.puts "Initializing Child Processes"
STDOUT.flush
child_procs = fork_kids(ivl_person_ids, family_map, h_packages, RECORDS_AT_ISSUE, ITERATION_RUN)
child_procs.each do |cproc|
  reader_map[cproc.first] = cproc.last
end

child_procs.each do |cproc|
  signal_writer = cproc[1]
  signal_writer.write("S")
  signal_writer.flush
  signal_writer.close
  STDOUT.puts "CHILD #{cproc.first} START SIGNAL SENT"
  STDOUT.flush
end

child_procs

family_map = nil
GC.start
MallocTrim.trim

pb = ProgressBar.create(
  :title => "Running records",
  :total => ivl_person_ids.length,
  :format => "%t %a %E %c/%C %P%%",
  :throttle_rate => 5.0
)

while !reader_map.empty?
  begin
    rs, _ws, _es = IO.select(reader_map.values, [], [], 30)
    if !rs.nil?
      rs.each do |r|
        values = r.read(1)
        if values
          pb.progress += values.length
        end
      end
    end
  rescue Errno::EBADF, IOError, Errno::EPIPE
    reader_map.reject do |k,v|
      begin
        v.stat
      rescue => e
        STDERR.puts e.inspect
        STDERR.flush
        true
      end
    end
  end
end