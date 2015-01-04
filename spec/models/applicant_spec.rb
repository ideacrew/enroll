require 'rails_helper'

describe Applicant do

  let(:b0) {Broker.create!(b_type: "broker", npn: "987432010", name_last: "popeye")}
  let(:p0) {Person.create!(name_first: "Dan", name_last: "Aurbach")}
  let(:p1) {Person.create!(name_first: "Patrick", name_last: "Carney")}
  let(:ag) {ApplicationGroup.create()}

  describe "indexes specified fields" do
  end

  describe "instantiates object." do
    it "sets and gets all basic model fields and embeds in parent class" do
      a = Applicant.new(
        person: p0,
        broker: b0,
        is_primary_applicant: true,
        is_coverage_applicant: true,
        is_consent_applicant: true,
        is_active: true
        )

      a.application_group = ag

      expect(a.broker.npn).to eql(b0.npn)
      expect(a.broker_id).to eql(b0._id)

      expect(a.person.name_last).to eql(p0.name_last)
      expect(a.person_id).to eql(p0._id)

      expect(a.is_primary_applicant?).to eql(true)
      expect(a.is_coverage_applicant?).to eql(true)
      expect(a.is_consent_applicant?).to eql(true)

    end
  end

  describe "performs validations" do
  end

end