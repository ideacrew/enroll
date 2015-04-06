module BradyBunch
  shared_context "BradyBunch" do
    def dob(num_years)
      Date.today - num_years.years
    end

    let(:brady_addr) do
      FactoryGirl.build(:address,
        kind: "home",
        address_1:
        "4222 Clinton Way",
        address_2: nil,
        city: "Washington",
        state: "DC",
        zip: "20011"
      )
    end
    let(:brady_ph) {FactoryGirl.build(:phone, kind: "home", area_code: "202", number: "7620799", extension: nil)}
    let(:last_name) {"Brady"}
    let(:mikes_age)   {40}
    let(:carols_age)  {35}
    let(:gregs_age)   {17}
    let(:marcias_age) {16}
    let(:peters_age)  {14}
    let(:jans_age)    {12}
    let(:bobbys_age)  {8}
    let(:cindys_age)  {6}
    let(:mike)   {FactoryGirl.create(:male,   first_name: "Mike",   last_name: last_name, dob: dob(mikes_age),   addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:carol)  {FactoryGirl.create(:female, first_name: "Carol",  last_name: last_name, dob: dob(carols_age),  addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:greg)   {FactoryGirl.create(:male,   first_name: "Greg",   last_name: last_name, dob: dob(gregs_age),   addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:marcia) {FactoryGirl.create(:female, first_name: "Marcia", last_name: last_name, dob: dob(marcias_age), addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:peter)  {FactoryGirl.create(:male,   first_name: "Peter",  last_name: last_name, dob: dob(peters_age),  addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:jan)    {FactoryGirl.create(:female, first_name: "Jan",    last_name: last_name, dob: dob(jans_age),    addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:bobby)  {FactoryGirl.create(:male,   first_name: "Bobby",  last_name: last_name, dob: dob(bobbys_age),  addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:cindy)  {FactoryGirl.create(:female, first_name: "Cindy",  last_name: last_name, dob: dob(cindys_age),  addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:brady_daughters) {[marcia, jan, cindy]}
    let(:brady_sons) {[greg, peter, bobby]}
    let(:brady_children) {brady_sons + brady_daughters}
    let(:bradys) {[mike, carol, greg, marcia, peter, jan, bobby, cindy]}
    let!(:mikes_family) do
      mike.person_relationships << PersonRelationship.new(relative_id: mike.id, kind: "self")
      mike.person_relationships << PersonRelationship.new(relative_id: carol.id, kind: "spouse")
      brady_children.each do |child|
        mike.person_relationships << PersonRelationship.new(relative_id: child.id, kind: "child")
      end
      mike.save

      family = FactoryGirl.build(:family)
      family.family_members << FactoryGirl.build(:family_member, :primary, person: mike)
      (bradys - [mike]).each do |brady|
        family.family_members << FactoryGirl.build(:family_member, person: brady)
      end
      family.save
      family
    end
    let!(:carols_family) do
      carol.person_relationships << PersonRelationship.new(relative_id: carol.id, kind: "self")
      carol.person_relationships << PersonRelationship.new(relative_id: mike.id, kind: "spouse")
      brady_children.each do |child|
        carol.person_relationships << PersonRelationship.new(relative_id: child.id, kind: "child")
      end
      carol.save

      family = FactoryGirl.build(:family)
      family.family_members << FactoryGirl.build(:family_member, :primary, person: carol)
      (bradys - [carol]).each do |brady|
        family.family_members << FactoryGirl.build(:family_member, person: brady)
      end
      family.save
      family
    end
    let(:mikes_coverage_household) {mikes_family.households.first.coverage_households.first}
    let(:carols_coverage_household) {carols_family.households.first.coverage_households.first}
  end

  shared_context "BradyWork" do
    include_context "BradyBunch"

    let(:mikes_work_addr) do
      FactoryGirl.build(:address,
        kind: "work",
        address_1:
        "6345 Reagan Road",
        address_2: nil,
        city: "Washington",
        state: "DC",
        zip: "20011"
      )
    end
    let(:mikes_work_ph) {FactoryGirl.build(:phone, kind: "home", area_code: "202", number: "5069292", extension: nil)}
    let(:mikes_office_location) do
      FactoryGirl.build(:office_location,
                        address: mikes_work_addr,
                        phone: mikes_work_phone
      )
    end
    let(:mikes_employer) {FactoryGirl.build(:employer_profile)}
    let(:mikes_organization) do
      FactoryGirl.create(:organization,
                         legal_name: "Mike's Architects Limited",
                         dba: "MAL",
                         office_locations: [mikes_office_location],
                         employer_profile: mikes_employer,
      )
    end
    let(:mikes_census_employee) do
      FactoryGirl.build(:employer_census_employee,
                        first_name: mike.first_name,  last_name: mike.last_name,
                        dob: mike.dob, address: mike.address
      )
    end
    let(:mikes_census_family) {FactoryGirl.create(:employer_census_family, employer_profile: mikes_employer, census_employee: mikes_census_employee)}
    let(:mikes_benefit_group) {FactoryGirl.build(:benefit_group, plan_year: nil)}
    let!(:mikes_plan_year) {FactoryGirl.create(:plan_year, employer_profile: mikes_employer, benefit_groups: [mikes_benefit_group])}

    let(:carols_work_addr) do
      FactoryGirl.build(:address,
        kind: "work",
        address_1:
        "1321 Carter Court",
        address_2: nil,
        city: "Washington",
        state: "DC",
        zip: "20011"
      )
    end
    let(:carols_work_ph) {FactoryGirl.build(:phone, kind: "home", area_code: "202", number: "6109987", extension: nil)}
    let(:carols_office_location) do
      FactoryGirl.build(:office_location,
                        address: carols_work_addr,
                        phone: carols_work_phone
      )
    end
    let(:carols_employer) {FactoryGirl.build(:employer_profile)}
    let(:carols_organization) do
      FactoryGirl.create(:organization,
                         legal_name: "Care Real S Tates",
                         dba: "CRST",
                         office_locations: [carols_office_location],
                         employer_profile: carols_employer,
      )
    end
    let(:carols_census_employee) do
      FactoryGirl.build(:employer_census_employee,
                        first_name: carol.first_name,  last_name: carol.last_name,
                        dob: carol.dob, address: carol.address
      )
    end
    let(:carols_census_family) {FactoryGirl.create(:employer_census_family, employer_profile: carols_employer, census_employee: carols_census_employee)}
    let(:carols_benefit_group) {FactoryGirl.build(:benefit_group, plan_year: nil)}
    let!(:carols_plan_year) {FactoryGirl.create(:plan_year, employer_profile: carols_employer, benefit_groups: [carols_benefit_group])}
  end
end
