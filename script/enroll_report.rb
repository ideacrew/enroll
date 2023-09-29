start_on = Date.yesterday.beginning_of_day
end_on = Date.today.end_of_day
range = start_on..end_on
user_count = User.where(created_at: range).count
person_count = Person.where(created_at: range).count
families_created_count = Family.where(created_at: range).count
families_updated_count = Family.where(updated_at: range).count
enrollment_created_count = HbxEnrollment.where(created_at: range, "effective_on" => {"$gte" => Date.new(2022,1,1)},
                                               :aasm_state.in => HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES).count
enrollments = HbxEnrollment.collection.aggregate([
 { "$match" => {
   "hbx_enrollment_members" => {"$ne" => nil},
   "external_enrollment" => {"$ne" => true},
   "consumer_role_id" => {"$ne" => nil},
   "product_id" => { "$ne" => nil},
   "aasm_state" => {"$in" =>  HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES},
   "effective_on" => {"$gte" => Date.new(2022,1,1)},
   "created_at" => { "$gte" => start_on, "$lte" => end_on}
 }},
{"$group" => {
    "_id" => "$product_id",
    "count" => {"$sum" =>  1}
}},
    {"$project" => {
        "_id" => 1,
        "count" => 1
    }},
])

filename="enroll_report_" + Time.zone.now.strftime("%Y%m%d") + ".txt"
f = File.new(filename, "a")
plan_ids = enrollments.collect {|i|i["_id"]}
products = BenefitMarkets::Products::Product.by_year(2022).where(:"id".in => plan_ids)
BenefitSponsors::Organizations::Organization.issuer_profiles.each do |issuer_org|
  by_issuer = products.by_issuer_profile_id(issuer_org.issuer_profile.id)
  issuer_total = enrollments.collect {|i| i["count"] if by_issuer.map(&:id).include?(i["_id"]) }.compact.sum
  f.puts("Total Active Enrollments Created After 11/1/2021 For Carrier: #{issuer_org.legal_name}, total: #{issuer_total}")
  [:catastrophic, :bronze, :silver, :gold, :dental, :platinum].each do |metal_level|
    by_metal_level = by_issuer.where(metal_level_kind: metal_level, :id.in => plan_ids)
    total = enrollments.collect {|i| i["count"] if by_metal_level.map(&:_id).include?(i["_id"]) }.compact.sum
    f.puts("For Metal Level #{metal_level}: #{total}")
  end
end
application_count = FinancialAssistance::Application.where(:created_at => range).count
f.puts("Total Application Created #{range}: #{application_count}")
f.puts("Total User Created #{range}: #{user_count}")
f.puts("Total Person Created #{range}: #{person_count}")
f.puts("Total Families Created #{range}: #{families_created_count}")
f.puts("Total Families Updated #{range}: #{families_updated_count}")
f.puts("Total Enrollemnt Created #{range}: #{enrollment_created_count}")
f.close
