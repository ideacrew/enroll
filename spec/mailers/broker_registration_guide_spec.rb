require 'rails_helper'

RSpec.describe UserMailer do
  describe 'broker_registration_guide' do
    let(:email){UserMailer.broker_registration_guide({first_name:'Broker',email:'Broker@test.com'})}

    it 'should not allow a reply' do
    	expect(email.from).to match([Settings.site.mail_address])
    end

    it 'should deliver to Broker' do
    	expect(email.to).to match(['Broker@test.com'])
    end

    it "should have subject of Broker Registration Guide" do
      expect(email.subject).to match("Broker Registration Guide")
    end

    it 'should have Broker Registration Guide as attachment' do
      attachment = email.attachments[0]
      expect(attachment.content_type).to include("application/pdf; filename=\"Broker Registration Guide.pdf\"")
      expect(attachment.filename).to eq 'Broker Registration Guide.pdf'
    end
  end
end