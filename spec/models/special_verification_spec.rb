require 'rails_helper'

describe SpecialVerification do

  it { should validate_presence_of :due_date }
  it { should validate_presence_of :verification_type }

  let(:verification_document_due) { EnrollRegistry[:verification_document_due_in_days].item }
  let(:params) {
    {
      due_date: TimeKeeper.date_of_record + verification_document_due.days,
      verification_type: "Citizenship",
      updated_by: double("AdminUser"),
      type: "admin"
    }
  }

  let(:subject) { SpecialVerification.new(**params)}

  it "should be valid record" do
    expect(subject.valid?).to eq true
  end

  it "should raise an error when saved without parent object" do
    expect {subject.save}.to raise_error(Mongoid::Errors::NoParent)
  end
end
