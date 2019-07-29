require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class ShopEnrollmentReport < MongoidMigrationTask
  def migrate
    if ENV['purchase_date_start'].blank? && ENV['purchase_date_end'].blank?
       # Purchase dates are from 30 days to todays date
      purchase_date_start = (Time.now - 30.days).beginning_of_day
      purchase_date_end = Time.now.end_of_day
    else
      purchase_date_start = Time.strptime(ENV['purchase_date_start'],'%m/%d/%Y').beginning_of_day
      purchase_date_end = Time.strptime(ENV['purchase_date_end'],'%m/%d/%Y').end_of_day
    end
    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")

    qs = Queries::PolicyAggregationPipeline.new
    qs.filter_to_shopping_completed
    qs.eliminate_family_duplicates
    qs.add({ "$match" => {"policy_purchased_at" => {"$gte" => purchase_date_start, "$lte" => purchase_date_end}}})
    glue_list = File.read("all_glue_policies.txt").split("\n").map(&:strip) if File.exist?("all_glue_policies.txt")
    enrollment_ids = []

    qs.evaluate.each do |r|
      enrollment_ids << r['hbx_id']
    end

    enrollment_ids_final = []
    enrollment_ids.each{|id| (enrollment_ids_final << id)}
    writing_on_csv(enrollment_ids_final, glue_list)
    puts "Shop Enrollment Report Generated" unless Rails.env.test?
  end

  def writing_on_csv(enrollment_ids_final, glue_list)
    shop_headers = ['Employer ID', 'Employer FEIN', 'Employer Name', 'Plan Year Start', 'Plan Year State', 'Employer State',
                    'Enrollment GroupID', 'Purchase Date', 'Coverage Start', 'Coverage End', 'Coverage Kind', 'Enrollment State', 
                    'Subscriber HBXID', 'Subscriber First Name','Subscriber Last Name', 'HIOS ID', 'Premium Subtotal', 
                    'ER Contribution', 'Applied APTC Amount', 'Total Responsible Amount', 'Family Size', 'Enrollment Reason', 'In Glue']
    file_name = "#{Rails.root}/hbx_report/shop_enrollment_report.csv"
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << shop_headers
      enrollment_ids_final.each_slice(300) do |en_slice|
        en_org_map = get_employer_profiles_for(en_slice)
        en_pers_map = get_people_for(en_slice)
        enrollment_map = Hash.new
        HbxEnrollment.where("hbx_id" => {"$in" => en_slice.to_a}).each do |en|
          enrollment_map[en.hbx_id] = en
        end
        en_slice.each do |id|
          begin
            hbx_enrollment = enrollment_map[id]
            next unless hbx_enrollment.is_shop?
            employer_profile =  if en_org_map.has_key?(id)
                                   en_org_map[id]
                                else
                                  hbx_enrollment.employer_profile
                                end
            enrollment_reason = enrollment_kind(hbx_enrollment)
            plan_year = hbx_enrollment.sponsored_benefit_package.benefit_application
            plan_year_start = plan_year.start_on.to_s
            if en_pers_map.has_key?(id)
              subscriber = en_pers_map[id]
              subscriber_hbx_id = subscriber.hbx_id
              first_name = subscriber.first_name
              last_name = subscriber.last_name
            end
            in_glue = glue_list.include?(id) if glue_list.present?
            csv << [employer_profile.hbx_id,employer_profile.fein,employer_profile.legal_name,plan_year_start,plan_year.aasm_state,
                    plan_year.benefit_sponsorship.aasm_state,hbx_enrollment.hbx_id,hbx_enrollment.created_at,hbx_enrollment.effective_on,
                    hbx_enrollment.terminated_on,hbx_enrollment.coverage_kind,hbx_enrollment.aasm_state,subscriber_hbx_id,first_name,
                    last_name,hbx_enrollment.product.hios_id,hbx_enrollment.total_premium,hbx_enrollment.total_employer_contribution,
                    hbx_enrollment.applied_aptc_amount,hbx_enrollment.total_employee_cost,hbx_enrollment.hbx_enrollment_members.size,
                    enrollment_reason,in_glue]
          rescue StandardError => e
            @logger = Logger.new("#{Rails.root}/log/shop_enrollment_report_error.log")
            (@logger.error { "Could not add the hbx_enrollment's information on to the CSV for eg_id:#{id}, subscriber_hbx_id:#{subscriber_hbx_id}, #{e.inspect}" }) unless Rails.env.test?
          end
        end
      end
    end
  end

  def get_people_for(enrollment_hbx_ids)
    p_en_id_map = Hash.new
    en_pers_map = Hash.new
    person_ids = Array.new
    HbxEnrollment.collection.aggregate([
      {"$match" => {"hbx_id" => {"$in" => enrollment_hbx_ids.to_a}}},
      {"$project" => {"hbx_id" => 1, "family_id" => 1}},
      {"$lookup" => {
        "from" => "families",
        "localField" => "family_id",
        "foreignField" => "_id",
        "as" => "family"
      }},
      {"$unwind" => "$family"},
      {"$project" => {"hbx_id" => 1, "family_id" => 1, "family.family_members" => 1}},
      {"$unwind" => "$family.family_members"},
      {"$match" => {"family.family_members.is_primary_applicant" => true}},
      {"$project" => {"hbx_id" => 1, "person_id" => "$family.family_members.person_id"}}
    ]).each do |rec|
      p_en_id_map[rec["hbx_id"]] = rec["person_id"]
      person_ids << rec["person_id"]
    end
    pers_id_map = Hash.new
    Person.where(
      "_id" => {"$in" => person_ids}  
    ).each do |person|
      pers_id_map[person.id] = person
    end
    p_en_id_map.each_pair do |k, v|
      if pers_id_map.has_key?(v)
        en_pers_map[k] = pers_id_map[v]
      end
    end
    en_pers_map
  end

  def get_employer_profiles_for(enrollment_hbx_ids)
    bs_id_map = Hash.new
    org_ids = Array.new
    en_org_map = Hash.new
    HbxEnrollment.collection.aggregate([
      {"$match" => {"hbx_id" => {"$in" => enrollment_hbx_ids.to_a}}},
      {"$project" => {"hbx_id" => 1, "benefit_sponsorship_id" => 1}},
      {"$lookup" => {
        "from" => "benefit_sponsors_benefit_sponsorships_benefit_sponsorships",
        "localField" => "benefit_sponsorship_id",
        "foreignField" => "_id",
        "as" => "benefit_sponsorship"
      }},
      {"$unwind" => "$benefit_sponsorship"},
      {"$project" => {"hbx_id" => 1, "organization_id" => "$benefit_sponsorship.organization_id"}}
    ]).each do |rec|
      bs_id_map[rec["hbx_id"]] = rec["organization_id"]
      org_ids << rec["organization_id"]
    end
    org_id_map = Hash.new
    BenefitSponsors::Organizations::Organization.where(
      "_id" => {"$in" => org_ids}  
    ).each do |org|
      org_id_map[org.id] = org
    end
    bs_id_map.each_pair do |k, v|
      if org_id_map.has_key?(v)
        en_org_map[k] = org_id_map[v]
      end
    end
    en_org_map
  end

  def enrollment_kind(hbx_enrollment)
    case hbx_enrollment.enrollment_kind
    when "special_enrollment"
      hbx_enrollment.special_enrollment_period.qualifying_life_event_kind.reason
    when "open_enrollment"
      hbx_enrollment.eligibility_event_kind
    end
  end
end