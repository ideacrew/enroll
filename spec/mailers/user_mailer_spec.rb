require 'rails_helper'

RSpec.describe UserMailer do
  describe 'generic_notice_alert' do
    let(:hbx_id) { rand(10000 )}
    let(:file){ Rails.root.join("spec","mailers","user_mailer_spec.rb").to_s }
    let(:email){UserMailer.generic_notice_alert('john', hbx_id, 'john@dc.gov' , {"file_name" => file})}

    it 'should not allow a reply' do
    	expect(email.from).to match(["no-reply@individual.dchealthlink.com"])
    end

    it 'should deliver to john' do
    	expect(email.to).to match(['john@dc.gov'])
      expect(email.html_part.body).to match(/Dear john/)
    end

    it "should have subject of #{Settings.site.short_name}" do
      expect(email.subject).to match(/DC Health Link/)
    end

    it "should have one attachment" do 
      expect(email.attachments.size).to eq 1
    end

  end

  describe '.send_employee_open_enrollment_invitation' do
    let(:benefit_group)     { FactoryGirl.build(:benefit_group)}
    let(:plan_year)         { FactoryGirl.create(:plan_year, benefit_groups: [benefit_group], aasm_state: 'published') }
    let(:employer_profile) { plan_year.employer_profile}
    let(:invitation)  { Invitation.invite_employee_for_open_enrollment!(census_employee) }
    let(:email) { UserMailer.send_employee_open_enrollment_invitation(census_employee.email_address, census_employee, invitation) }

    context 'should send invite_initial_employee_for_open_enrollment when census_employee DOH is in the past' do
      let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, hired_on: TimeKeeper.date_of_record.prev_day) }

      it 'should match from address' do
        expect(email.from).to match(['no-reply@shop.dchealthlink.com'])
      end

      it 'should have subject' do
        expect(email.subject).to match(/Invitation from your Employer to Sign up for Health Insurance at DC Health Link/)
      end

      it 'should have proper content' do
        expect(email.body.raw_source).to have_content(/has chosen to offer health insurance coverage to its employee/)
      end
    end

    context 'should send invite_future_employee_for_open_enrollment when census_employee DOH is in the future' do
      let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, hired_on: TimeKeeper.date_of_record.next_day) }

      it 'should match from address' do
        expect(email.from).to match(['no-reply@shop.dchealthlink.com'])
      end

      it 'should have subject' do
        expect(email.subject).to match(/Invitation from your Employer to Sign up for Health Insurance at DC Health Link/)
      end

      it 'should have proper content' do
        expect(email.body.raw_source).to have_content(/has invited you to sign up for employer-sponsored health insurance through/)
      end
    end

  end
end
