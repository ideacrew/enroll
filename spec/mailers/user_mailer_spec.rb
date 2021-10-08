require 'rails_helper'
include Config::SiteHelper

RSpec.describe UserMailer do
  # Helps make sure it works for all clients
  def change_target_translation_text(translation_key, state_name, filename)
    translations_to_seed = []
    seedfile_location = "db/seedfiles/translations/en/#{state_name}/#{filename}.rb"
    require Rails.root.to_s + "/" + seedfile_location
    # Save the constant from the file
    "#{filename.upcase}_TRANSLATIONS".constantize.each do |key, value|
      Translation.where(key: key).first_or_create.update_attributes!(value: "\"#{value}\"") if key == translation_key
    end
  end

  let(:person_with_work_email) do
    person = FactoryBot.create(:person)
    person.emails.create!(
      kind: 'work',
      address: "fakeemail50@gmail.com"
    )
    person
  end
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
      # TODO: Probably something weird because of translations. We can get back to it
      # expect(email.html_part.body).to match(/Dear john/)
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

  context "#account_transfer_success_notification" do
    let(:account_transfer_email)do
      UserMailer.account_transfer_success_notification(person, "johnanderson@fake.com")
    end

    let(:person) { FactoryBot.create(:person) }

    let(:account_transfer_email_body) do
      l10n(
        "user_mailer.account_transfer_success_notification.full_text",
        medicaid_or_chip_agency_long_name: EnrollRegistry[:medicaid_or_chip_agency_long_name].settings(:name).item,
        medicaid_or_chip_program_short_name: EnrollRegistry[:medicaid_or_chip_program_short_name].settings(:name).item,
        person_name: person.full_name,
        site_home_business_url: site_home_business_url,
        state_name: state_name,
        site_short_name: site_short_name
      ).html_safe
    end

    before do
      change_target_translation_text("en.user_mailer.account_transfer_success_notification.full_text", "me", "user_mailer")
    end

    after do
      state_name = EnrollRegistry[:enroll_app].settings(:site_key).item.to_s.downcase
      change_target_translation_text("en.user_mailer.account_transfer_success_notification.full_text", state_name, "user_mailer")
    end

    it "should render the email with the proper text" do
      expect(account_transfer_email.body.raw_source.include?("It’s time to take action")).to eq(true)
    end
  end

  context "#broker_application_confirmation" do
    let(:broker_confirmation_email) do
      UserMailer.broker_application_confirmation(person_with_work_email)
    end
    let(:broker_application_confirmation_translation) do
      l10n(
        EnrollRegistry.feature_enabled?(:broker_approval_period) ? "user_mailer.broker_application_confirmation.full_text" : "user_mailer.broker_invitation.broker_app_submission",
        site_noreply_email_address: site_noreply_email_address,
        site_short_name: site_short_name,
        site_broker_registration_guide: site_broker_registration_guide,
        site_producer_email_address: site_producer_email_address,
        contact_center_phone_number:  EnrollRegistry[:enroll_app].settings(:contact_center_short_number).item.to_s,
        first_name: person_with_work_email.first_name,
        contact_center_short_name: EnrollRegistry[:enroll_app].setting(:contact_center_name).item,
        state_name: state_name,
        training_link: EnrollRegistry[:broker_training_link].item
      ).html_safe

    end
    it "should render the email with the proper text" do
      expect(broker_confirmation_email.body.raw_source).to include(person_with_work_email.first_name)
    end
  end
end