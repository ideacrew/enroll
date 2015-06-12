require 'rails_helper'

describe EmployerCensus::Employee, '.new', dbclean: :after_each do
  it { should validate_presence_of :ssn }
  it { should validate_presence_of :dob }
  it { should validate_presence_of :hired_on }

  let(:census_family) { FactoryGirl.build(:employer_census_family) }
  let(:census_employee) { census_family.census_employee }

  let(:first_name){ "Lynyrd" }
  let(:middle_name){ "Rattlesnake" }
  let(:last_name){ "Skynyrd" }
  let(:name_sfx){ "PhD" }
  let(:ssn){ "230987654" }
  let(:dob){ Date.today }
  let(:gender){ "male" }
  let(:address) { Address.new(kind: "home", address_1: "address 1", city: "new city", state: "new state", zip: "11111") }

  let(:employee_params){
    {
      first_name: first_name,
      middle_name: middle_name,
      last_name: last_name,
      name_sfx: name_sfx,
      ssn: ssn,
      dob: dob,
      gender: gender,
      hired_on: Date.today - 14.days,
      address: address
    }
  }
  it 'properly intantiates the class' do
    employee = EmployerCensus::Employee.new(**employee_params)

    expect(employee.first_name).to eq first_name
    expect(employee.middle_name).to eq middle_name
    expect(employee.last_name).to eq last_name
    expect(employee.name_sfx).to eq name_sfx
    expect(employee.ssn).to eq ssn
    expect(employee.dob).to eq dob
    expect(employee.gender).to eq gender

    # Class should set this attribute
    expect(employee.employee_relationship).to eq "self"

    # expect(employee.inspect).to eq 0
    expect(employee.valid?).to eq true
    expect(employee.is_linkable?).to be_falsey
    expect(employee.errors.messages.size).to eq 0
  end

  it "checks if employee is_linkable? " do
    census_employee.save
    expect(census_employee.is_linkable?).to be_truthy
  end
end

describe EmployerCensus::Employee, '.edit', dbclean: :after_each do
  let(:census_family) { FactoryGirl.build(:employer_census_family) }
  let(:employee) {FactoryGirl.create(:employer_census_employee, employee_family: census_family)}
  let(:user) {FactoryGirl.create(:user)}
  let(:hbx_staff) { FactoryGirl.create(:user, :hbx_staff) }
  let(:employer_staff) { FactoryGirl.create(:user, :employer_staff) }

  context "hbx staff user" do
    it "can change dob" do
      allow(User).to receive(:current_user).and_return(hbx_staff)
      employee.dob = Date.current
      expect(employee.save).to be_truthy
    end

    it "can change ssn" do
      allow(User).to receive(:current_user).and_return(hbx_staff)
      employee.ssn = "123321456"
      expect(employee.save).to be_truthy
    end
  end

  context "employer staff user" do
    before do
      allow(User).to receive(:current_user).and_return(employer_staff)
    end

    context "not linked" do
      before do
        allow(employee).to receive(:is_linkable?).and_return(true)
      end

      it "can change dob" do
        employee.dob = Date.current
        expect(employee.save).to be_truthy
      end

      it "can change ssn" do
        employee.ssn = "123321456"
        expect(employee.save).to be_truthy
      end
    end

    context "has linked" do
      before do
        allow(employee).to receive(:is_linkable?).and_return(false)
      end

      it "can not change dob" do
        employee.dob = Date.current
        expect(employee.save).to eq false
      end

      it "can not change ssn" do
        employee.ssn = "123321458"
        expect(employee.save).to eq false
      end
    end
  end

  context "normal user" do
    it "can not change dob" do
      allow(User).to receive(:current_user).and_return(user)
      employee.dob = Date.current
      expect(employee.save).to eq false
    end

    it "can not change ssn" do
      allow(User).to receive(:current_user).and_return(user)
      employee.ssn = "123321458"
      expect(employee.save).to eq false
    end
  end
end
