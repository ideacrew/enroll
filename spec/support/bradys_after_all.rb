module BradysAfterAll
  shared_context "BradyBunchAfterAll" do
    before :all do
      mikes_coverage_household
      carols_coverage_household
    end

    def dob(num_years)
      Date.today - num_years.years
    end

    def build_brady_address
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

    def build_brady_phone 
      FactoryGirl.build(:phone, kind: "home", area_code: "202", number: "7620799", extension: nil)
    end

    def female_brady(name, age)
      FactoryGirl.create(:female, first_name: name, last_name: "Brady", dob: dob(age), addresses: [build_brady_address], phones: [build_brady_phone])
    end

    def male_brady(name, age)
      FactoryGirl.create(:male, first_name: name, last_name: "Brady", dob: dob(age), addresses: [build_brady_address], phones: [build_brady_phone])
    end

    def mikes_age; 40; end
    def carols_age; 35; end
    def gregs_age; 17; end
    def marcias_age; 16; end
    def peters_age; 14; end
    def jans_age; 12; end
    def bobbys_age; 8; end
    def cindys_age; 6; end
    def mike 
      @mike ||= male_brady("Mike", mikes_age)
    end

    def carol
      @carol ||= female_brady("Carol", carols_age)
    end
    def greg
      @greg ||= male_brady("Greg", gregs_age)
    end

    def marcia
      @marcia ||= female_brady("Marcia", marcias_age)
    end

    def peter
      @peter ||= male_brady("Peter", peters_age)
    end

    def jan
      @jan ||= female_brady("Jan", jans_age)
    end
    def bobby
      @bobby ||= male_brady("Bobby", bobbys_age)
    end

    def cindy
      @cindy ||= female_brady("Cindy", cindys_age)
    end

    def brady_daughters
      @brady_daughters ||= [marcia, jan, cindy]
    end
    def brady_sons
      @brady_sons ||= [greg, peter, bobby]
    end
    def brady_children
      @brady_children ||= brady_sons + brady_daughters
    end
    def bradys
        @bradys ||= [mike, carol, greg, marcia, peter, jan, bobby, cindy]
    end
    def mikes_family
      return @mikes_family if @mikes_family
      mike.person_relationships << PersonRelationship.new(relative_id: mike.id, kind: "self")
      mike.person_relationships << PersonRelationship.new(relative_id: carol.id, kind: "spouse")
      brady_children.each do |child|
        mike.person_relationships << PersonRelationship.new(relative_id: child.id, kind: "child")
      end
      mike.save

      family = FactoryGirl.build(:family)
      family.add_family_member(mike, is_primary_applicant: true)
      (bradys - [mike]).each do |brady|
        family.add_family_member(brady)
      end
      family.save
      @mikes_family = family
    end
    def carols_family
      return @carols_family if @carols_family
      carol.person_relationships << PersonRelationship.new(relative_id: carol.id, kind: "self")
      carol.person_relationships << PersonRelationship.new(relative_id: mike.id, kind: "spouse")
      brady_children.each do |child|
        carol.person_relationships << PersonRelationship.new(relative_id: child.id, kind: "child")
      end
      carol.save

      family = FactoryGirl.build(:family)
      family.add_family_member(carol, is_primary_applicant: true)
      (bradys - [carol]).each do |brady|
        family.add_family_member(brady)
      end
      family.save
      @carols_family = family
    end
    def mikes_coverage_household 
      @mikes_coverage_household ||= mikes_family.households.first.coverage_households.first
    end
    def carols_coverage_household
        @carols_coverage_household ||= carols_family.households.first.coverage_households.first
    end
  end
end
