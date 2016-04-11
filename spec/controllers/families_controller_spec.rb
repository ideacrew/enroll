require 'rails_helper'

RSpec.describe FamiliesController do

 context "set_family before every action" do
    
    let(:person) {FactoryGirl.create(:person);}
    let(:user) { FactoryGirl.create(:user, :person=>person) }

    it "writes an error log message when @person OR @person.primary_family is blank" do
      sign_in(user)
      expect(subject).to receive(:log) do |msg, severity|
        expect(severity[:severity]).to eq('error')
        expect(msg[:message]).to eq('@family was set to nil')
      end
      expect(subject).to receive(:redirect_to).with("/500.html")
      subject.instance_eval{set_family}
    end

  end

end