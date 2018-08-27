namespace :fixture_dump do
  desc "Dump the person_relationship and related models"
  task :generate_applications => :environment do

    app_hbx_ids = ENV["app_hbx_ids"].to_s

    hashed_hbx_ids = app_hbx_ids.split(",")
    hashed_hbx_ids = hashed_hbx_ids.map {|x| x = x.split(":"); Hash[x.first, x.last]}
    hashed_hbx_ids = hashed_hbx_ids.reduce(:merge)

    puts "started downloading"
    hashed_hbx_ids.keys.each do |key|

      p_rec= Person.by_hbx_id(hashed_hbx_ids[key])
      application = p_rec.first.primary_family.latest_submitted_application
      next unless application.present?

      u_name = File.join(Rails.root, "db", "fixture_dumps", "application_#{key}.yaml")

      File.open(u_name, 'w') do |f|
        f.write application.to_yaml
      end
      print "."
    end
    puts "applications generated successfully"
  end

  task :load_applications => :environment do

    glob_pattern = File.join(Rails.root, "db", "fixture_dumps", "application_*.yaml")

    puts "started uploading"

    Dir.glob(glob_pattern).each do |f_name|

      loaded_class = ::FinancialAssistance::Application
      loaded_class_2 = ::FinancialAssistance::Applicant
      loaded_class_3 = ::FinancialAssistance::Income
      loaded_class_3_1 = ::Address
      loaded_class_3_2 = ::Phone
      loaded_class_4 = ::FinancialAssistance::Benefit
      loaded_class_4_1 = ::Address
      loaded_class_4_2 = ::Phone
      loaded_class_5 = ::FinancialAssistance::Deduction
      loaded_class_6 = ::FinancialAssistance::AssistedVerification

      yaml_str = File.read(f_name)
      app_fixture = YAML.load(yaml_str)
      oim_id = f_name.split("/")[-1].split("_")[-1].split(".")[0]
      family = User.where(oim_id: oim_id.to_s).first.person.primary_family
      family.applications.where(aasm_state: "draft").update_all(aasm_state: "submitted" , submitted_at: TimeKeeper.date_of_record )

      app_fixture.assign_attributes(id: generate_bson_id_for_fixtures, family_id: family.id, hbx_id: generate_hbx_id_for_fixtures,
                                    aasm_state: "draft", created_at: Time.now.utc, updated_at: nil,
                                    submitted_at: nil, determination_http_status_code: nil)
      count = 0

      app_fixture.applicants.each do |applicant|
        applicant.assign_attributes(id: generate_bson_id_for_fixtures, family_member_id: family.family_members[count].id,
                                    created_at: Time.now.utc, updated_at: nil, tax_household_id: nil)

        applicant.incomes.each do |income|
          income.assign_attributes(id: generate_bson_id_for_fixtures, created_at: Time.now.utc, updated_at: nil)

          if income.employer_address.present?
            income.employer_address.assign_attributes(id: generate_bson_id_for_fixtures, created_at: Time.now.utc, updated_at: nil)
          end

          if income.employer_phone.present?
            income.employer_phone.assign_attributes(id: generate_bson_id_for_fixtures, created_at: Time.now.utc, updated_at: nil)
          end
        end

        applicant.benefits.each do |benefit|
          benefit.assign_attributes(id: generate_bson_id_for_fixtures, created_at: Time.now.utc, updated_at: nil)

          if benefit.employer_address.present?
            benefit.employer_address.assign_attributes(id: generate_bson_id_for_fixtures, created_at: Time.now.utc, updated_at: nil)
          end

          if benefit.employer_phone.present?
            benefit.employer_phone.assign_attributes(id: generate_bson_id_for_fixtures, created_at: Time.now.utc, updated_at: nil)
          end
        end

        applicant.deductions.each do |deduction|
          deduction.assign_attributes(id: generate_bson_id_for_fixtures, created_at: Time.now.utc, updated_at: nil)
          deduction.created_at = TimeKeeper.date_of_record
          deduction.updated_at = nil
        end

        applicant.assisted_verifications.each do |assisted_verification|
          assisted_verification.assign_attributes(id: generate_bson_id_for_fixtures, created_at: Time.now.utc, updated_at: nil)

          if assisted_verification.assisted_verification_documents.present?
            assisted_verification.assisted_verification_documents.each do |assisted_verification_document|
              assisted_verification_document.assign_attributes(id: generate_bson_id_for_fixtures, created_at: Time.now.utc, updated_at: nil)
            end
          end

          if assisted_verification.verification_response.present?
            assisted_verification.verification_response.assign_attributes(id: generate_bson_id_for_fixtures, created_at: Time.now.utc, updated_at: nil)
          end
        end

        count = count +1
      end

      app_fixture.new_record = true
      app_fixture.save!
      print "."
    end
    puts "applications loaded successfully"
  end
end

def generate_hbx_id_for_fixtures
  HbxIdGenerator.generate_application_id
end

def generate_bson_id_for_fixtures
  BSON::ObjectId.new
end