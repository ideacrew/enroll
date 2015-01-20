require 'rails_helper'

RSpec.describe FamilyMember, :type => :model do
  let(:b0) {Broker.create!(b_type: "broker", npn: "987432010", last_name: "popeye")}
  let(:p0) {Person.create!(first_name: "Dan", last_name: "Aurbach")}
  let(:p1) {Person.create!(first_name: "Patrick", last_name: "Carney")}
  let(:ag) {Family.create()}

  describe "indexes specified fields" do
  end

  describe "instantiates object." do
    it "sets and gets all basic model fields and embeds in parent class" do
      a = FamilyMember.new(
        person: p0,
        broker: b0,
        is_primary_applicant: true,
        is_coverage_applicant: true,
        is_consent_applicant: true,
        is_active: true
        )

      a.family = ag

      expect(a.broker.npn).to eql(b0.npn)
      expect(a.broker_id).to eql(b0._id)

      expect(a.person.last_name).to eql(p0.last_name)
      expect(a.person_id).to eql(p0._id)

      expect(a.is_primary_applicant?).to eql(true)
      expect(a.is_coverage_applicant?).to eql(true)
      expect(a.is_consent_applicant?).to eql(true)

    end
  end

  describe "performs validations" do
  end
end
