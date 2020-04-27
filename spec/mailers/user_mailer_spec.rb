require 'rails_helper'
  include Config::SiteHelper
RSpec.describe UserMailer do
  describe 'generic_notice_alert' do
    let(:hbx_id) { rand(10000 )}
    let(:file){ Rails.root.join("spec","mailers","user_mailer_spec.rb").to_s }
    let(:email){UserMailer.generic_notice_alert('john', hbx_id, 'john@dc.gov' , {"file_name" => file})}
    let(:new_client_email){UserMailer.new_client_notification("agent@email.com", "Client", "Client New", "Consumer", "client@new.com", true)}

    it 'should not allow a reply' do
      expect(email.from).to match(["no-reply@individual.#{site_domain_name}"])
    end

    it 'should deliver to john' do
      expect(email.to).to match(['john@dc.gov'])
      expect(email.html_part.body).to match(/Dear john/)
    end

    it "should have subject of #{Settings.site.short_name}" do
      expect(email.subject).to match(/#{Settings.site.short_name}/)
    end

    it "should have one attachment" do
      expect(email.attachments.size).to eq 1
    end

    it "should render new client's information" do
      expect(new_client_email.body).to match("Client New")
      expect(new_client_email.body).to match("client@new.com")
    end

  end
end
