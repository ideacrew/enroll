# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserMailer do
  include Config::SiteHelper
  include TranslationSpecHelper
  let(:person_with_work_email) do
    person = FactoryBot.create(:person)
    person.emails.create!(
      kind: 'work',
      address: "fakeemail50@gmail.com"
    )
    person
  end

  describe 'tax_form_notice_alert' do
    let(:subject) {"You have a new tax document from #{site_short_name}" }
    let(:file){ Rails.root.join("spec","mailers","user_mailer_spec.rb").to_s }
    let(:contact_center_phone_number) { EnrollRegistry[:enroll_app].setting(:health_benefit_exchange_authority_phone_number)&.item }
    let(:email){UserMailer.tax_form_notice_alert(person_with_work_email.first_name,'john@example.com')}
    let(:email_body) { l10n('user_mailer.tax_form_notice_alert.full_text', first_name: 'John', site_short_name: site_short_name,  contact_center_phone_number: contact_center_phone_number, site_home_business_url: site_home_business_url) }

    it 'should not allow a reply' do
      expect(email.from).to match(["no-reply@individual.#{site_domain_name}"])
    end

    it 'should deliver to John' do
      expect(email.to).to match(['john@example.com'])
    end

    it "should have body" do
      expect(email.body.include?(email_body)).to be_truthy
    end
  end

  describe 'generic_notice_alert' do
    let(:hbx_id) { rand(10_000)}
    let(:file){ Rails.root.join("spec","mailers","user_mailer_spec.rb").to_s }
    let(:email){UserMailer.generic_notice_alert('john', hbx_id, 'john@dc.gov', {"file_name" => file})}
    let(:new_client_email){UserMailer.new_client_notification("agent@email.com", "Client", "Consumer", "client@new.com", "123456")}

    it 'should not allow a reply' do
      expect(email.from).to match(["no-reply@individual.#{site_domain_name}"])
    end

    it 'should deliver to john' do
      expect(email.to).to match(['john@dc.gov'])
      # TODO: Probably something weird because of translations. We can get back to it
      # expect(email.html_part.body).to match(/Dear john/)
    end

    it "should have subject of #{EnrollRegistry[:enroll_app].setting(:short_name).item}" do
      expect(email.subject).to match(/#{EnrollRegistry[:enroll_app].setting(:short_name).item}/)
    end

    it "should have one attachment" do
      expect(email.attachments.size).to eq 1
    end

    it "should render new client's information" do
      expect(new_client_email.body).to match("Client")
      expect(new_client_email.subject).to match("client@new.com")
    end
  end

  context "#account_transfer_success_notification" do
    let(:account_transfer_email) do
      UserMailer.account_transfer_success_notification(person, "johnanderson@fake.com", "123456")
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
        contact_center_phone_number: EnrollRegistry[:enroll_app].settings(:contact_center_short_number).item.to_s,
        first_name: person_with_work_email.first_name,
        contact_center_short_name: EnrollRegistry[:enroll_app].setting(:contact_center_name).item,
        state_name: state_name,
        training_link: EnrollRegistry[:broker_training_link].item,
        contact_center_tty_number: EnrollRegistry[:enroll_app].setting(:contact_center_tty_number).item
      ).html_safe

    end
    it "should render the email with the proper text" do
      expect(broker_confirmation_email.body.raw_source).to include(person_with_work_email.first_name)
    end
  end

  context "#identity_verification_denial" do
    let(:hbx_id) { rand(10_000)}
    let(:identity_verification_denial) do
      UserMailer.identity_verification_denial(person_with_work_email, person_with_work_email.first_name, hbx_id)
    end
    let(:identity_verification_denial_translation) do
      l10n(
        site_short_name: site_short_name,
        contact_center_phone_number: EnrollRegistry[:enroll_app].settings(:contact_center_short_number).item.to_s,
        first_name: person_with_work_email.first_name
      ).html_safe

    end
    it "should render the email with the proper text" do
      expect(identity_verification_denial.body.raw_source).to include(person_with_work_email.first_name)
    end
  end
end

RSpec.describe UserMailer, "sending a approval linked notification email for a broker or broker staff" do
  include Config::SiteHelper

  let(:email) { "some-broker@adomain.com"}
  let(:name) { "Broker Name"}

  subject { UserMailer.broker_or_broker_staff_linked_invitation_email(email, name) }

  it "has the login link" do
    expect(subject.body.raw_source.include?("href=#{site_main_web_address_url}")).to be_truthy
  end

  it "has the greeting" do
    expect(subject.body.raw_source.include?("Hi #{name},")).to be_truthy
  end
end