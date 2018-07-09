namespace :cca do
  desc "Restore Person/Enrollment HbxIds for MPYC"
  task :restore_hbx_ids_for_mpy_conversions => :environment do
    file_path = File.join(Rails.root, 'db', 'seedfiles', "mpyc_policies_and_people.csv")

    MPY_EFFECTIVE_DATES = [Date.new(2018, 4, 1), Date.new(2018, 5, 1)]
    file = Roo::Spreadsheet.open(file_path)
    sheet = file.sheet(0)
    columns = sheet.row(1)
    @person_prod_sequence = ENV["person_sequence"].present? ? ENV["person_sequence"].to_i : 130000
    @policy_prod_sequence = ENV["policy_sequence"].present? ? ENV["policy_sequence"].to_i : 130000

    puts "*** Started restoring person HBX ID/ Enrollment HBX ID ****"
    puts "**** Note: IF primary person restore failed, we're not restoring corresponding Enrollment's Hbx ID ****"

    def find_people(ssn, dob, last_name)
      Person.all.matchable(ssn, dob, last_name)
    end

    def parse_text(val)
      return nil if val.blank?
      val.strip
    end

    def parse_ssn(val)
      return nil if val.blank?
      val.split(".")[0].strip.rjust(9, '0')
    end

    def parse_date(val)
      return nil if val.blank?
      Date.strptime(val.strip, "%m/%d/%Y")
    end

    def initiate_dependent_restore(dependents, hbx_id, last_name)
      if dependents.size != 1
        puts "FAILURE: Found No primary person/More than 1 on record with last_name: #{last_name}. HbxId: #{hbx_id} failed"
        puts "Moving on to other dependents..."
      else
        dependent = dependents.first
        restore_person_hbx_id(dependent, hbx_id, false)
      end
    end

    def restore_person_hbx_id(person, hbx_id, is_primary)
      prev_hbx_id = person.hbx_id
      type = is_primary ? "Subscriber" : "Dependent"
      if prev_hbx_id.to_i < @person_prod_sequence
        puts "Info: This is an existing #{type}. Not restoring HbxId for #{person.full_name} ** HbxId: #{prev_hbx_id}"
        return true
      end
      person.assign_attributes(hbx_id: hbx_id)
      if person.save
        puts "SUCCESS: HbxId updated for #{type} #{person.full_name} from #{prev_hbx_id} to #{hbx_id}"
      else
        puts "FAILURE: Hbx Id not updated for #{type} #{person.full_name} with errors: #{person.errors.full_messages}. HbxId: #{hbx_id} failed"
      end
    end

    def restore_policy_hbx_id(policy, hbx_id, person)
      prev_hbx_id = policy.hbx_id
      if prev_hbx_id.to_i < @policy_prod_sequence
        puts "Info: This is an existing Policy. Not restoring HbxId for Policy of #{person.full_name} ** Policy HbxId: #{prev_hbx_id}"
        return true
      end
      policy.assign_attributes(hbx_id: hbx_id)
      if policy.save
        puts "SUCCESS: Policy HbxId updated for #{person.full_name} from #{prev_hbx_id} to #{hbx_id}"
      else
        puts "Policy Hbx Id not updated on #{person.full_name} with errors: #{policy.errors.full_messages}. Enrollment HbxId: #{hbx_id} failed"
      end
    end

    def pluck_mpyc_policy(policies, hios_id, primary_hbx_id, legal_name)
      policies = policies.select {|policy| policy.product.present? && policy.product.hios_id == hios_id}

      if policies.size != 1
        organizations = ::BenefitSponsors::Organizations::Organization.all.where(legal_name: legal_name)

        if organizations.size != 1
          puts "FAILURE: Found More than 1 organization with legal_name: #{legal_name}. Policy HBX ID Restore failed. Subscriber hbx_id: #{primary_hbx_id}"
          return
        end

        applications = organizations.first.active_benefit_sponsorship.benefit_applications

        application = applications.where(:"effective_period.min".in => MPY_EFFECTIVE_DATES).first
        if application.nil?
          puts "FAILURE: Policy restore failed on Subscriber: #{primary_hbx_id} because of no MPY"
          return
        end
        pacakge_ids = application.benefit_packages.map(&:id)

        policies = policies.select {|policy| pacakge_ids.include?(policy.sponsored_benefit_package_id) && policy.product.present? && policy.product.hios_id == hios_id }

        if policies.blank?
          puts "FAILURE: Policy restore failed on Subscriber: #{primary_hbx_id} because no policy Found for MPY"
          return
        end

        if policies.size > 1
          puts "FAILURE: Policy restore failed on Subscriber: #{primary_hbx_id} found multiple Policies found for MPY"
          return
        end

        policies.first
      else
        policies.first
      end
    end

    (2..sheet.last_row).each do |key|
      row = Hash[[columns, sheet.row(key)].transpose]
      primary_ssn = parse_ssn(row["census_employee_ssn"])
      primary_last_name = parse_text(row["census_employee_last_name"])
      primary_first_name = parse_text(row["census_employee_first_name"])
      primary_dob = parse_date(row["census_employee_dob"])
      restorable_hbx_id = parse_text(row["census_employee_hbx_id"])
      people = find_people(primary_ssn, primary_dob, primary_last_name)

      if people.blank?
        puts "FAILURE: Found No person record with #{primary_first_name} #{primary_last_name}"
        puts "Skipping dependents information for this person if any..."
        next
      end

      if people.size != 1
        puts "FAILURE: Found More than 1 person record with #{primary_first_name} #{primary_last_name}"
        puts "Skipping dependents information for this person if any..."
        next
      end

      primary_person = people.first

      if restorable_hbx_id.present?
        restore_person_hbx_id(primary_person, restorable_hbx_id, true)
      end

      Array(1..6).each do |i|
        dependent_ssn = parse_ssn(row["Dep#{i} SSN"])
        dependent_last_name = parse_text(row["Dep#{i} Last Name"])
        dependent_dob = parse_date(row["Dep#{i} DOB"])
        dependent_restorable_hbx_id = parse_text(row["Dependent#{i} HBX ID"])

        break if dependent_last_name.blank?

        if dependent_restorable_hbx_id.present?
          dependents = find_people(dependent_ssn, dependent_dob, dependent_last_name)
          initiate_dependent_restore(dependents, dependent_restorable_hbx_id, dependent_last_name)
        end
      end

      begin
        policy_restorable_hbx_id = parse_text(row["census_employee_policy_id"])
        
        next if policy_restorable_hbx_id.blank?

        policies = primary_person.primary_family.active_household.hbx_enrollments

        if policies.blank?
          puts "FAILURE: Spreadsheet has policy Hbx Id. But no Enrollment present in Subscriber account. Person HbxId: #{primary_person.hbx_id} "
          next
        end

        if policies.size > 1
          # MPYC should only have 1 enrollment in their account. You should never hit this.
          # puts "MPYC EE account should not have more than one enrollment.  <Remove 'next' in the code below to process this if valid case>"
          # next
          policy = pluck_mpyc_policy(policies, row["hios_id"], primary_person.hbx_id, row["legal_name"])
          if policy.present?
            restore_policy_hbx_id(policy, policy_restorable_hbx_id, primary_person)
          end
        else
          restore_policy_hbx_id(policies.first, policy_restorable_hbx_id, primary_person)
        end
      rescue Exception => e
        puts "FAILURE: Error while updating policy #{policy_restorable_hbx_id}: #{e}"
      end
    end

    puts "***** Finished Updating Person/Enrollment Hbx Id's"
  end
end
