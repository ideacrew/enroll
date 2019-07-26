require "rails_helper"

describe CensusEmployee, ".lacking_predecessor_assignment_for_application_as_of query" do

  let(:benefit_sponsorship_id) { BSON::ObjectId.new }
  let(:benefit_package_id) { BSON::ObjectId.new }

  let(:benefit_package) do
    instance_double(
      BenefitSponsors::BenefitPackages::BenefitPackage,
      id: benefit_package_id
    )
  end

  let(:benefit_sponsorship) do
    instance_double(
      BenefitSponsors::BenefitSponsorships::BenefitSponsorship,
      id: benefit_sponsorship_id
    )
  end

  let(:package_start_on) { (new_effective_date - 1.year) }
  let(:package_end_on) { (new_effective_date - 1.day) }

  let(:predecessor_application) do
    instance_double(
      BenefitSponsors::BenefitApplications::BenefitApplication,
      start_on: package_start_on,
      end_on: package_end_on,
      benefit_packages: [benefit_package],
      benefit_sponsorship: benefit_sponsorship
    )
  end

  let(:new_effective_date) { Date.new(2019, 5, 1) }

  describe "given:
    - a census employee with no benefit group assignments
    - that matches the date criteria
  ", dbclean: :after_each do

    subject do
      CensusEmployee.lacking_predecessor_assignment_for_application_as_of(
        predecessor_application,
        new_effective_date
      )
    end

    let(:census_employee_id) { BSON::ObjectId.new }

    before :each do
      CensusMember.collection.insert_one({
        "_id" => census_employee_id,
        "benefit_sponsorship_id" => benefit_sponsorship_id,
        "hired_on" => new_effective_date,
        "_type" => "CensusEmployee"
      })
    end

    it "finds the census employee" do
      expect(subject.map(&:id)).to include(census_employee_id)
    end
  end

  describe "given:
  - a census employee with an empty set of benefit group assignments
  - that matches the date criteria
  ", dbclean: :after_each do

    subject do
      CensusEmployee.lacking_predecessor_assignment_for_application_as_of(
        predecessor_application,
        new_effective_date
      )
    end

    let(:census_employee_id) { BSON::ObjectId.new }

    before :each do
      CensusMember.collection.insert_one({
        "_id" => census_employee_id,
        "benefit_sponsorship_id" => benefit_sponsorship_id,
        "hired_on" => new_effective_date,
        "benefit_group_assignments" => [],
        "_type" => "CensusEmployee"
      })
    end

    it "finds the census employee" do
      expect(subject.map(&:id)).to include(census_employee_id)
    end
  end

  describe "given:
  - a census employee with a benefit group assignment for another package
    over the same time period
  - that matches the date criteria
  ", dbclean: :after_each do

    let(:another_package_id) { BSON::ObjectId.new }

    subject do
      CensusEmployee.lacking_predecessor_assignment_for_application_as_of(
        predecessor_application,
        new_effective_date
      )
    end

    let(:census_employee_id) { BSON::ObjectId.new }

    before :each do
      CensusMember.collection.insert_one({
        "_id" => census_employee_id,
        "benefit_sponsorship_id" => benefit_sponsorship_id,
        "hired_on" => package_start_on,
        "benefit_group_assignments" => [
          {
            "benefit_package_id" => another_package_id,
            "start_on" => package_start_on,
            "end_on" => package_end_on
          }
        ],
        "_type" => "CensusEmployee",
        "employment_terminated_on" => new_effective_date
      })
    end

    it "finds the census employee" do
      expect(subject.map(&:id)).to include(census_employee_id)
    end
  end

  describe "given:
  - a census employee with a benefit group assignment for this package
    but ends early
  - that matches the date criteria
  ", dbclean: :after_each do

    let(:another_package_id) { BSON::ObjectId.new }

    subject do
      CensusEmployee.lacking_predecessor_assignment_for_application_as_of(
        predecessor_application,
        new_effective_date
      )
    end

    let(:census_employee_id) { BSON::ObjectId.new }

    before :each do
      CensusMember.collection.insert_one({
        "_id" => census_employee_id,
        "benefit_sponsorship_id" => benefit_sponsorship_id,
        "hired_on" => package_start_on,
        "benefit_group_assignments" => [
          {
            "benefit_package_id" => benefit_package_id,
            "start_on" => package_start_on,
            "end_on" => (package_end_on - 1.day)
          }
        ],
        "_type" => "CensusEmployee"
      })
    end

    it "finds the census employee" do
      expect(subject.map(&:id)).to include(census_employee_id)
    end
  end

  describe "given:
  - a census employee with a benefit group assignment for this package
  - but already fired
  ", dbclean: :after_each do

    subject do
      CensusEmployee.lacking_predecessor_assignment_for_application_as_of(
        predecessor_application,
        new_effective_date
      )
    end

    let(:census_employee_id) { BSON::ObjectId.new }

    before :each do
      CensusMember.collection.insert_one({
        "_id" => census_employee_id,
        "benefit_sponsorship_id" => benefit_sponsorship_id,
        "hired_on" => new_effective_date,
        "benefit_group_assignments" => [
          {
            "benefit_package_id" => benefit_package_id,
            "start_on" => package_start_on,
            "end_on" => package_end_on
          }
        ],
        "_type" => "CensusEmployee",
        "employment_terminated_on" => package_end_on
      })
    end

    it "does not find the census employee" do
      expect(subject.map(&:id)).not_to include(census_employee_id)
    end
  end

  describe "given:
  - a census employee with a benefit group assignment for this package
  - that matches the date criteria
  ", dbclean: :after_each do

    subject do
      CensusEmployee.lacking_predecessor_assignment_for_application_as_of(
        predecessor_application,
        new_effective_date
      )
    end

    let(:census_employee_id) { BSON::ObjectId.new }

    before :each do
      CensusMember.collection.insert_one({
        "_id" => census_employee_id,
        "benefit_sponsorship_id" => benefit_sponsorship_id,
        "hired_on" => new_effective_date,
        "benefit_group_assignments" => [
          {
            "benefit_package_id" => benefit_package_id,
            "start_on" => package_start_on,
            "end_on" => package_end_on
          }
        ],
        "_type" => "CensusEmployee"
      })
    end

    it "does not find the census employee" do
      expect(subject.map(&:id)).not_to include(census_employee_id)
    end
  end

  describe "given:
  - a census employee with a benefit group assignment for this package
  - and has another package as well
  - that matches the date criteria
  ", dbclean: :after_each do

    let(:another_package_id) { BSON::ObjectId.new }

    subject do
      CensusEmployee.lacking_predecessor_assignment_for_application_as_of(
        predecessor_application,
        new_effective_date
      )
    end

    let(:census_employee_id) { BSON::ObjectId.new }

    before :each do
      CensusMember.collection.insert_one({
        "_id" => census_employee_id,
        "benefit_sponsorship_id" => benefit_sponsorship_id,
        "hired_on" => new_effective_date,
        "benefit_group_assignments" => [
          {
            "benefit_package_id" => benefit_package_id,
            "start_on" => package_start_on,
            "end_on" => package_end_on
          },
          {
            "benefit_package_id" => another_package_id,
            "start_on" => package_start_on,
            "end_on" => package_end_on
          }
        ],
        "_type" => "CensusEmployee"
      })
    end

    it "does not find the census employee" do
      expect(subject.map(&:id)).not_to include(census_employee_id)
    end
  end
end