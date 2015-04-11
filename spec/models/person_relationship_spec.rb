require 'rails_helper'


describe PersonRelationship, type: :model do
  it { should validate_presence_of :relative_id }
  it { should validate_presence_of :kind }

  let(:kind) {"spouse"}
  let(:person) {FactoryGirl.create(:person, gender: "male", dob: "10/10/1974", ssn: "123456789" )}

  describe ".new" do
    let(:valid_params) do
      { kind: kind,
        relative: person,
        person: person
      }
    end

    let(:kinds) {  [
      "parent",
      "grandparent",
      "aunt_or_uncle",
      "nephew_or_niece",
      "father_or_mother_in_law",
      "daughter_or_son_in_law",
      "brother_or_sister_in_law",
      "adopted_child",
      "stepparent",
      "foster_child",
      "sibling",
      "ward",
      "stepchild",
      "sponsored_dependent",
      "dependent_of_a_minor_dependent",
      "guardian",
      "court_appointed_guardian",
      "collateral_dependent",
      "life_partner",
      "spouse",
      "child",
      "grandchild",
      "trustee", # no inverse
      "annuitant", # no inverse,
      "other_relationship",
      "unrelated",
      "great_grandparent",
      "great_grandchild"
  ] }


    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(PersonRelationship.new(**params).save).to be_falsey
      end
    end

    context "with no kind" do
      let(:params) {valid_params.except(:kind)}

      it "should fail validation " do
        expect(PersonRelationship.create(**params).errors[:kind].any?).to be_truthy
      end
    end

    context "with no relative" do
      let(:params) {valid_params.except(:relative)}

      it "should fail validation " do
        expect(PersonRelationship.create(**params).errors[:relative_id].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params) {valid_params}
      it "should save" do
        expect(PersonRelationship.new(**params).save).to be_truthy
      end
    end

    context "with all valid kinds" do
      let(:params) {valid_params}
      it "should save" do
        kinds.each do |rkind|
          params[:kind] = rkind
          expect(PersonRelationship.new(**params).save).to be_truthy
        end
      end
    end
  end
end

