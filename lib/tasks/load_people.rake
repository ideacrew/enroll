def load_irs_families_seed
    if File.exists?("db/seedfiles/irs_groups.csv")
      member_ids = {}
      family_mappings = {}
      CSV.foreach("db/seedfiles/irs_groups.csv", :headers => true) do |row|
        rec = row.to_hash
        m_id = row['hbx_id']
        family_mappings[m_id] = rec
      end
      member_ids_records = Person.collection.aggregate([{
       "$project" => { "hbx_id" => 1 }
      }])
      member_ids_records.each do |m_id_rec|
        member_ids[m_id_rec['hbx_id']] = m_id_rec['_id'].to_s
      end
      family_props_mappings = {}
      family_mappings.each_pair do |k, v|
        mapped_person = member_ids[k]
        if !mapped_person.nil?
          family_props_mappings[mapped_person] = v
        end
      end
      primary_applicant_list = Family.collection.raw_aggregate([
        {"$unwind" => "$family_members"},
        {"$match" => {"family_members.is_primary_applicant" => true}},
        {"$project" => {"_id" => "$family_members.person_id"}}
      ]).map { |r| r['_id'].to_s }
      miss_rate = primary_applicant_list - family_props_mappings.keys
      puts miss_rate.first
      puts miss_rate.length
      all_families = ::Family.unscoped.all
      total_families = all_families.count
      puts "Processing #{total_families} families for irs groups"
      chunk_number = 50
      chunk = total_families.to_f/(chunk_number.to_f)
      milestone = chunk
      all_families.each_with_index do |fam, idx|
        pa_id = fam.primary_applicant.person_id.to_s
        if family_props_mappings.has_key?(pa_id)
          changed_rec = false
          family_props = family_props_mappings[pa_id]
          irs_group = fam.irs_groups.first
          new_group_number = family_props['irs_group_id']
          if irs_group.hbx_assigned_id != new_group_number
            irs_group.hbx_assigned_id = new_group_number
            irs_group.touch
            fam.touch
            changed_rec = true
          end
          new_e_case_id = family_props['e_case_id']
          if fam.e_case_id != new_e_case_id
            fam.e_case_id = new_e_case_id
            changed_rec = true
          end
          if changed_rec
            fam.save!
          end
        end
        if idx > milestone
          milestone = milestone + chunk
          puts idx 
          current_value = ((idx.to_f/total_families.to_f) * 100.00).round
          puts "Loaded #{current_value}% of families"
        end
      end
    end
end


namespace :seed do
  desc "Load the people data"
  task :people => :environment do
    Person.delete_all
    file = File.open("db/seedfiles/people.json", "r")
    contents = file.read
    file.close
    data = JSON.load(contents)
    puts "Loading #{data.count} people."
    num_success = data.reduce(0) do |acc, pd|
      begin
      person = Person.create!(pd)
      rescue
        raise pd.inspect
      end
      person.valid? ? acc + 1 : acc
    end
    puts "Loaded #{num_success} people successfully."
  end

  desc "Load the family data"
  task :families => :environment do
    Family.delete_all
    if File.exists?("db/seedfiles/heads_of_families.json")
      puts "Loading families"
      file = File.open("db/seedfiles/heads_of_families.json")
      heads_of_family = JSON.load(file.read)
      file.close
      puts "Loading #{heads_of_family.length} families"
      families_built = 0
      total_families = heads_of_family.length
      chunk_number = 20
      chunk = total_families.to_f/(chunk_number.to_f)
      milestone = chunk
      Person.each do |person|
        if heads_of_family.include?(person.id.to_s)
          Family.new.build_from_person(person).save!
          families_built = families_built + 1
          if families_built > milestone
            milestone = milestone + chunk
            current_value = ((families_built.to_f/total_families.to_f) * 100.00).round
            puts "Loaded #{current_value}% of families"
          end
        end
      end
      puts "Loaded #{families_built} families successfully"
    end
    load_irs_families_seed
  end

  desc "Load the core29 families data"
  task :core29_people => :environment do
    file_user = File.open("db/core29_seedfiles/core_faa_families.json", "r")
    contents_user = file_user.read
    file_user.close

    data_user = JSON.load(contents_user)
    puts "Loading #{data_user.count} user."
    num_success = data_user.reduce(0) do |acc, ud|
      hashed_data = Hash[*ud.flatten]
      begin
        user_email = hashed_data["user"].first["email"]
        user_oim_id = hashed_data["user"].first["oim_id"]
        existing_user = User.all.where(email: user_email).and(oim_id: user_oim_id).first
        if existing_user.present?
          # existing_user.person.primary_family.destroy if existing_user.person.primary_family.present?
          # if existing_user.person.person_relationships.count >0
          #   existing_user.person.person_relationships.each do |a|
          #     Person.where(id: a.relative_id).first.destroy
          #   end
          # end
          existing_user.person.destroy if existing_user.person.present?
          existing_user.destroy
        end
        user = User.create!(hashed_data["user"])
        person = Person.new(hashed_data["person"].first)
        ssn = generate_ssn
        dob = generate_dob(hashed_data["person_age"])
        person.ssn = ssn
        person.dob = dob
        person.update_attributes(user: user.first)
        person.save!
        consumer_role = ConsumerRole.new(hashed_data["consumer_role"].first)
        consumer_role.update_attributes(person: person)
        consumer_role.save!
        family = Family.new.build_from_person(person)
        family.save!
        col_count = hashed_data.count
        dependent_count = col_count-6
        dependents_id = []

        while hashed_data.count >6 && dependent_count!=0 do

          dependent = Person.new(hashed_data["dependent#{dependent_count}"].first["dependent"].first)
          dob = generate_dob(hashed_data["dependent#{dependent_count}"].first["dependent_age"])
          dependent.dob = dob
          if !hashed_data["dependent#{dependent_count}"].first["dependent"].first["no_ssn"].present?
            ssn = generate_ssn
            dependent.ssn = ssn
          end
          dependent.save!
          dependents_id << dependent.id
          if hashed_data["dependent#{dependent_count}"].first["consumer_role"].present?
            consumer_role = ConsumerRole.new(hashed_data["dependent#{dependent_count}"].first["consumer_role"].first)
            consumer_role.update_attributes(person: dependent)
            consumer_role.save!
          end
          person.person_relationships.new(kind: hashed_data["dependent#{dependent_count}"].first["kind"], predecessor_id: dependent.id, successor_id: person.id, family_id: family.id)
          person.save!
          family.family_members.create!(person_id: dependent.id)
          family.relate_new_member(dependent, hashed_data["dependent#{dependent_count}"].first["kind"])
          family.save!
          dependent_count=dependent_count-1
        end

        if hashed_data["relation_ships"].first["rs1"].first["kind"].present?
          if hashed_data["relation_ships"].first.count >0
            count = hashed_data["relation_ships"].count
            while count!=0 do
              # rs = hashed_data["relation_ships"].first["rs#{count}"].first
              rs = hashed_data["relation_ships"][count-1]["rs#{count}"].first
              generate_relation(dependents_id.reverse[rs["predecessor"]-1], dependents_id.reverse[rs["successor"]-1], rs["kind"], family.id)
              count =count -1
            end
          end
        end

        family.reload
        family.build_relationship_matrix
        application = family.applications.new
        application.populate_applicants_for(family)
        application.save!
      rescue
        raise ud.inspect
      end
      # user.valid? ? acc + 1 : acc
    end
    puts "Loaded #{num_success} person successfully."

  end

end

def generate_ssn
  ssn = 0
  count =0
  while count==0 do
    puts "in ssn"
    ssn = rand(999999999).to_s.center(9, rand(9).to_s).to_i
    if Person.where(ssn: ssn).count < 1
      count = count+1
    end
  end
  ssn
end

def generate_dob(age)
  current_date = TimeKeeper.date_of_record
  dob = Date.new(current_date.year-age,current_date.month,current_date.day)
end


def generate_relation(person_id,dependent_id,kind,family_id)
  predecessor = Person.where(id: person_id).first
  successor = Person.where(id: dependent_id).first
  predecessor.add_relationship(successor, kind,family_id, true)
  successor.add_relationship(predecessor, PersonRelationship::InverseMap[kind], family_id)
end
