AUDIT_START_DATE = Date.new(2018,10,1)
AUDIT_END_DATE = Date.new(2019,10,1)

STDOUT.puts "Standard caching complete."
STDOUT.flush

hbx = HbxProfile.current_hbx
bcps = hbx.benefit_sponsorship.benefit_coverage_periods
bcp = bcps.detect { |bcp| bcp.start_on.year == 2019 }
health_benefit_packages = bcp.benefit_packages.select do |bp|
  (bp.title.include? "health_benefits")
end

puts "Health Benefit Packages located."
STDOUT.flush

non_curam_ivl = Person.collection.aggregate([
  {"$project" => {
    _id: 1,
    created_at: 1,
    updated_at: 1,
    consumer_role: 1
  }},
  {"$match" => {
    "consumer_role._id" => {"$ne" => nil},
    "$or" => [
      {"created_at" => {"$gte" => AUDIT_START_DATE}},
      {"created_at" => {"$lt" => AUDIT_START_DATE}, "updated_at" => {"$gte" => AUDIT_START_DATE}}
    ]
  }},
  {"$project" => {_id: 1}}
])

ivl_person_ids = non_curam_ivl.map do |rec|
  rec["_id"]
end

STDOUT.puts "Counted #{ivl_person_ids.count} people."
STDOUT.flush

ivl_people = Person.where("_id" => {"$in" => ivl_person_ids})

families_of_interest = Family.where(
  {"family_members.person_id" => {"$in" => ivl_person_ids}}
)

STDOUT.puts "Counted #{families_of_interest.count} families."
STDOUT.flush

# Let's cache the family mappings
person_family_map = Hash.new { |h,k| h[k] = Array.new }

families_of_interest.each do |fam|
  fam.family_members.each do |fm|
    person_family_map[fm.person_id] = person_family_map[fm.person_id] + [fam]
  end
end

# So what we need here is: family_membership * person_record * version_numbers_for_person
person_id_count = ivl_person_ids.count
STDOUT.puts person_id_count.inspect
STDOUT.puts families_of_interest.count
STDOUT.flush

def relationship_for(person, family)
  return "self" if (person.id == family.primary_applicant.person_id)
  from_rel = person.find_relationship_with(family.primary_applicant.person)
  return from_rel if !from_rel.blank?
  family.primary_applicant.person.find_relationship_with(person)
end

def version_in_window?(updated_at)
  (updated_at >= AUDIT_START_DATE) && (updated_at < AUDIT_END_DATE)
end

def calc_eligibility_for(cr, family, benefit_packages, ed)
  effective_date = (ed < Date.new(2019,1,1)) ? Date.new(2019,1,1) : ed
  benefit_packages.any? do |hbp|
    InsuredEligibleForBenefitRule.new(cr, hbp, {new_effective_on: effective_date, family: family, version_date: ed, market_kind: "individual"}).satisfied?.first
  end
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

pb = ProgressBar.create(
  :title => "Running records",
  :total => person_id_count,
  :format => "%t %a %e |%B| %P%%"
)
CSV.open("audit_ivl_determinations.csv", "w") do |csv|
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
    "Residency Exemption Reason",
    "Is applying for coverage",
    "Eligible"
  ]
  ivl_people.no_timeout.each do |pers_record|
    pers_record.reload
    clean_history_tracks = pers_record.history_tracks.reject do |ht|
      ((ht.created_at.to_f - pers_record.created_at.to_f).abs < 1.1)
    end
    person_versions = [pers_record] + pers_record.versions + clean_history_tracks
    if pers_record.versions.empty? && pers_record.history_tracks.any?
      person_versions = person_versions + [pers_record.created_at]
    end
    person_versions.each do |p_version|
      begin
      p_version, person_updated_at = if p_version.kind_of?(HistoryTracker)
        if (p_version.created_at >= AUDIT_END_DATE) || (p_version.created_at < AUDIT_START_DATE)
          next
        end
        # This will be a HistoryTracker
        [pers_record.history_tracker_to_record(p_version.created_at), p_version.created_at]
      elsif p_version.kind_of?(Date) || p_version.kind_of?(ActiveSupport::TimeWithZone)
        if (p_version < AUDIT_START_DATE) || (p_version >= AUDIT_END_DATE)
          next
        end
        [pers_record.history_tracker_to_record(p_version), p_version]
      else
        [p_version, p_version.updated_at]
      end
      if (person_updated_at < AUDIT_START_DATE) || (person_updated_at >= AUDIT_END_DATE)
        next
      end
      families = person_family_map[pers_record.id]
      # This "pers" variable will be the version that is appended to the CSV
      pers = p_version
      families.each do |fam|
        cr = pers.consumer_role
        if cr
          if cr.person.blank?
            cr.person = p_version
          end
          begin
            if auditable?(pers_record, p_version, person_updated_at, fam)
              eligible = calc_eligibility_for(cr, fam, health_benefit_packages, person_updated_at)
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
                  relationship_for(pers_record, fam),
                  lpd.citizen_status,
                  (lpd.citizen_status.nil? ? nil : (lpd.citizen_status == "indian_tribe_member")),
                  pers.is_incarcerated] +
                  address_fields +
                  mailing_address_fields +
                  [
                    pers.no_dc_address ? pers.no_dc_address_reason : "",
                    cr.is_applying_coverage,
                    eligible
                ])
              end
            end          
          rescue Mongoid::Errors::DocumentNotFound => e
            puts e.inspect
          end
        end
      end
      rescue HistoryTrackerReversalError => htre
        STDERR.puts htre.inspect
        STDERR.flush
        next  
      end
    end
    pb.increment
  end
end
