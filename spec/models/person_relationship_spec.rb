require 'rails_helper'

describe PersonRelationship do
  subject { PersonRelationship.new(
    :subject_person => subject_person,
    :object_person => object_person
  )}

  let(:subject_person) { Person.new }
  let(:object_person) { Person.new }

  relationship_values = [
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
  ]

  relationship_values.each do |rv|
    context("given a relationship_kind of #{rv}") do
      it "should be valid" do
        subject.relationship_kind = rv
        expect(subject).to be_valid
      end
    end
  end
end
