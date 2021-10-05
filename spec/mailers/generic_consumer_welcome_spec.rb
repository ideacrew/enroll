require 'rails_helper'

RSpec.describe UserMailer do
  let(:site_short_name) { EnrollRegistry[:enroll_app].setting(:short_name).item }
  describe 'generic_consumer_welcome' do
    let(:hbx_id) { rand(10000 )}
    let(:email){UserMailer.generic_consumer_welcome('john', hbx_id, 'john@dc.gov')}

    it 'should not allow a reply' do
      expect(email.from.first).to match(/no-reply@individual./)
    end

    it 'should deliver to john' do
      expect(email.to).to match(['john@dc.gov'])
      expect(email.body).to match(/Dear john/)
    end

    it "should have subject of site short name" do
      expect(email.subject).to match(/#{site_short_name}/)
    end

    it 'should have body text' do
      expect(email.body).to match(/You have a new message from #{site_short_name}/)
      expect(email.body).to match(/Your Account/)
      expect(email.body).to match(/Please log in to your account/)
    end
  end
end
