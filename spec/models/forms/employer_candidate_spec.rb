require "rails_helper"

describe Forms::EmployerCandidate do
  before :each do
    subject.valid?
  end

  it "should have error on fein" do
    expect(subject).to have_errors_on(:fein)
  end

  it "should have errors on legal name" do
    expect(subject).to have_errors_on(:legal_name)
  end
end

describe Forms::EmployerCandidate, "asked to match an employer" do
  let(:fake_org) { instance_double("Organization", :fein => "123456789", :employer_profile => fake_employer) }

  subject {
    Forms::EmployerCandidate.new({
      :fein => "123456789",
      :legal_name => "fake company name"
    })
  }

  let(:search_params) { {
    :fein => "123456789",
    :legal_name => "fake company name"
  } }

  it "should return nothing if the company does not exist" do
    allow(::EmployerProfile).to receive(:find_by_fein).and_return(nil)
    expect(subject.match_employer).to be_nil
  end

  context "who does not have a managing staff associated" do
    let(:fake_employer) { instance_double("EmployerProfile", :staff_roles => []) }

    it "should return the employer profile" do
      allow(::EmployerProfile).to receive(:find_by_fein).and_return(fake_employer)
      expect(subject.match_employer).to eq fake_employer
    end
  end

  context "who does have an owner associated" do
    let(:owned_employer) { instance_double("EmployerProfile", :staff_roles => double) }

    it "should have an error on the employer profile" do
      allow(::EmployerProfile).to receive(:find_by_fein).and_return(owned_employer)
      subject.valid?
      expect(subject).to have_errors_on(:base)
    end
  end

end
