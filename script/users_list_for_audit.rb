z=[]
start_date = Date.new(2015,10,12)
end_date = Date.new(2016,9,30)

families = Family.by_enrollment_effective_date_range(Date.new(2016,1,1), Date.new(2016,12,31)).where(:"created_at" => { "$gte" => start_date, "$lte" => end_date}, :"e_case_id" => nil, :"households.hbx_enrollments.kind" => "individual", :"households.hbx_enrollments.aasm_state".in => (HbxEnrollment::CANCELED_STATUSES || (HbxEnrollment::TERMINATED_STATUSES - ["unverified", "void"])))
families.each do |family|
  begin
    primary_fm = family.primary_family_member
    next if primary_fm.person.user.blank?
    next if family.households.flat_map(&:hbx_enrollments).any? {|enr| enr.effective_on < Date.new(2016,1,1)}
    family.family_members.each do |fm|
      begin
        citizen_status = fm.person.citizen_status.try(:humanize) || "No Info"                
          z << fm.person.hbx_id if citizen_status == "No Info"
      rescue => e
        puts "#{e}"
      end
    end
  rescue => e
    puts "#{e}"
  end
end
puts "Count: #{z.size} & List: #{z}"