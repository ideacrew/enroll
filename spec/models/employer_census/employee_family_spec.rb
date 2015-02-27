require 'rails_helper'

describe EmployerCensus::EmployeeFamily, type: :model do
  it { should validate_presence_of :census_employee }

  let(:employer) {FactoryGirl.create(:employer)}
  let(:census_employee) {FactoryGirl.build(:employer_census_employee)}

  describe ".new" do
    let(:valid_params) do
      { 
        employer: employer,
        census_employee: census_employee
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(EmployerCensus::EmployeeFamily.new(**params).save).to be_false
      end
    end

    context "with no employer" do
      let(:params) {valid_params.except(:employer)}

      it "should raise" do
        expect{EmployerCensus::EmployeeFamily.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no census_employee" do
      let(:params) {valid_params.except(:census_employee)}

      it "should fail validation" do
        expect(EmployerCensus::EmployeeFamily.create(**params).errors[:census_employee].any?).to be_true
      end
    end

    context "with all required data" do
      let(:params) {valid_params}

      it "should successfully save" do
        expect(EmployerCensus::EmployeeFamily.new(**params).save).to be_true
      end
    end
  end

  # let(:terminated) {false}
  # let(:plan_year) {FactoryGirl.create(:plan_year)}
  # let(:benefit_group) {FactoryGirl.create(:benefit_group)}
  # let(:linked_employee) {FactoryGirl.create(:employee)}
  # let(:linked_at) {Date.today}
  # let(:census_dependent) {FactoryGirl.create(:employer_census_dependent)}
  #       census_dependents: census_dependent.to_a,
        # terminated: terminated,
        # plan_year: plan_year,
        # benefit_group: benefit_group,
        # linked_employee: linked_employee,
        # linked_at: linked_at

  # Class methods
  describe EmployerCensus::EmployeeFamily, '.new', :type => :model do

  end

  describe EmployerCensus::EmployeeFamily, '.find', :type => :model do
    it 'returns EmployerCensus::EmployeeFamily instance for the specified ID' do
      # b0 = EmployerCensus::EmployeeFamily.create(person: person0, npn: npn0, provider_kind: provider_kind)

      # expect(EmployerCensus::EmployeeFamily.find(b0._id)).to be_an_instance_of EmployerCensus::EmployeeFamily
      # expect(EmployerCensus::EmployeeFamily.find(b0._id).npn).to eq b0.npn
    end
  end

  describe EmployerCensus::EmployeeFamily, '.all', :type => :model do
    it 'returns all EmployerCensus::EmployeeFamily instances' do
      # b0 = EmployerCensus::EmployeeFamily.create(person: person0, npn: npn0, provider_kind: provider_kind)
      # b1 = EmployerCensus::EmployeeFamily.create(person: person1, npn: npn1, provider_kind: provider_kind)

      # # expect(EmployerCensus::EmployeeFamily.all).to be_an_instance_of Mongoid::Criteria
      # expect(EmployerCensus::EmployeeFamily.all.last).to be_an_instance_of EmployerCensus::EmployeeFamily
      # expect(EmployerCensus::EmployeeFamily.all.size).to eq 2
    end
  end

  describe EmployerCensus::EmployeeFamily, '.find_by_npn', :type => :model do
    it 'returns EmployerCensus::EmployeeFamily instance for the specified National Producer Number' do
    #   b0 = EmployerCensus::EmployeeFamily.create(person: person0, npn: npn0, provider_kind: provider_kind)
    #   b1 = EmployerCensus::EmployeeFamily.create(person: person1, npn: npn1, provider_kind: provider_kind)

    #   expect(EmployerCensus::EmployeeFamily.find_by_npn(npn0).npn).to eq b0.npn
    end
  end


  describe EmployerCensus::EmployeeFamily, '.find_by_EmployerCensus::EmployeeFamily_agency', :type => :model do
    # let(:ba) {FactoryGirl.create(:EmployerCensus::EmployeeFamily_agency)}

    it 'returns EmployerCensus::EmployeeFamily instance for the specified National Producer Number' do
      # b0 = EmployerCensus::EmployeeFamily.create(person: person0, npn: npn0, provider_kind: provider_kind, EmployerCensus::EmployeeFamily_agency: ba)
      # b1 = EmployerCensus::EmployeeFamily.create(person: person1, npn: npn1, provider_kind: provider_kind, EmployerCensus::EmployeeFamily_agency: ba)

      # expect(EmployerCensus::EmployeeFamily.find_by_EmployerCensus::EmployeeFamily_agency(ba).size).to eq 2
      # expect(EmployerCensus::EmployeeFamily.find_by_EmployerCensus::EmployeeFamily_agency(ba).first.EmployerCensus::EmployeeFamily_agency_id).to eq ba._id
    end
  end


  describe EmployerCensus::EmployeeFamily, '.all', :type => :model do
    it 'returns all EmployerCensus::EmployeeFamily instances' do
      # b0 = EmployerCensus::EmployeeFamily.create(person: person0, npn: npn0, provider_kind: provider_kind)
      # b1 = EmployerCensus::EmployeeFamily.create(person: person1, npn: npn1, provider_kind: provider_kind)

      # # expect(EmployerCensus::EmployeeFamily.all).to be_an_instance_of Mongoid::Criteria
      # expect(EmployerCensus::EmployeeFamily.all.last).to be_an_instance_of EmployerCensus::EmployeeFamily
      # expect(EmployerCensus::EmployeeFamily.all.size).to eq 2
    end
  end

  # Instance methods
  describe EmployerCensus::EmployeeFamily, :type => :model do
    # let(:ba) {FactoryGirl.create(:EmployerCensus::EmployeeFamily_agency)}

    it '#EmployerCensus::EmployeeFamily_agency sets agency' do
      # expect(EmployerCensus::EmployeeFamily.new(EmployerCensus::EmployeeFamily_agency: ba).EmployerCensus::EmployeeFamily_agency.id).to eq ba._id
    end

    it '#has_EmployerCensus::EmployeeFamily_agency? is true when agency is assigned' do
      # expect(EmployerCensus::EmployeeFamily.new(EmployerCensus::EmployeeFamily_agency: nil).has_EmployerCensus::EmployeeFamily_agency?).to be_false
      # expect(EmployerCensus::EmployeeFamily.new(EmployerCensus::EmployeeFamily_agency: ba).has_EmployerCensus::EmployeeFamily_agency?).to be_true
    end

    # TODO
    it '#address= and #address sets & gets work address on parent person instance' do
      # address = FactoryGirl.build(:address)
      # address.kind = "work"
      
      # expect(person0.build_EmployerCensus::EmployeeFamily(address: address).address._id).to eq address._id
      # expect(person0.build_EmployerCensus::EmployeeFamily(npn: npn0, provider_kind: provider_kind, address: address).save).to eq true
    end
  end

end



describe EmployerCensus::EmployeeFamily, '#clone', type: :model do
  it 'creates a copy of this instance' do
    # user - FactoryGirl.create(:user)
    er = FactoryGirl.create(:employer)
    ee = FactoryGirl.build(:employer_census_employee)
    ee.address = FactoryGirl.build(:address)

    family = er.employee_families.build(census_employee: ee)
    # family.link(user)
    family.census_employee.hired_on = Date.today - 1.year
    family.census_employee.terminated_on = Date.today - 10.days
    ditto = family.clone

    expect(ditto.census_employee).to eq ee
    expect(ditto.census_employee.hired_on).to be_nil
    expect(ditto.census_employee.terminated_on).to be_nil
    expect(ditto.census_employee.address).to eq ee.address

    expect(ditto.linked_employee_id).to be_nil
    expect(ditto.is_linked?).to eq false

  end
end
