module BradyBunch
  shared_context "BradyBunch" do
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
    let(:mike)   {FactoryGirl.create(:male,   first_name: "Mike",   last_name: last_name, dob: 40.years.ago, addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:carol)  {FactoryGirl.create(:female, first_name: "Carol",  last_name: last_name, dob: 35.years.ago, addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:greg)   {FactoryGirl.create(:male,   first_name: "Greg",   last_name: last_name, dob: 17.years.ago, addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:marcia) {FactoryGirl.create(:female, first_name: "Marcia", last_name: last_name, dob: 16.years.ago, addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:peter)  {FactoryGirl.create(:male,   first_name: "Peter",  last_name: last_name, dob: 14.years.ago, addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:jan)    {FactoryGirl.create(:female, first_name: "Jan",    last_name: last_name, dob: 12.years.ago, addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:bobby)  {FactoryGirl.create(:male,   first_name: "Bobby",  last_name: last_name, dob: 8.years.ago,  addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:cindy)  {FactoryGirl.create(:female, first_name: "Cindy",  last_name: last_name, dob: 6.years.ago,  addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:bradys) {[mike, carol, greg, marcia, peter, jan, bobby, cindy]}
    let!(:mikes_family) do
      family = FactoryGirl.create(:family)
      family.family_members << FactoryGirl.build(:family_member, :primary, person: mike)
      (bradys - [mike]).each do |brady|
        family.family_members << FactoryGirl.build(:family_member, person: brady)
      end
      family.save
      family
    end
    let!(:carols_family) do
      family = FactoryGirl.create(:family)
      family.family_members << FactoryGirl.build(:family_member, :primary, person: carol)
      (bradys - [carol]).each do |brady|
        family.family_members << FactoryGirl.build(:family_member, person: brady)
      end
      family.save
      family
    end
  end
end
