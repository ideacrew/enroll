require 'rails_helper'

module BenefitSponsors

  RSpec.describe Organizations::OrganizationForms::RegistrationForm, type: :model, dbclean: :after_each do

    let!(:site)  { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :cca) }
    subject { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm }

    describe '#for_new' do

      context "profile_type = benefit_sponsor" do

        it 'instantiates a new registration form for employer profile' do
          form = subject.for_new(profile_type:"benefit_sponsor")
          expect(form.profile_type).to eq 'benefit_sponsor'
          expect(form.profile_id).to eq nil
          expect(form.organization).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::OrganizationForm)
          expect( form.organization.profile.parent).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::OrganizationForm)
          expect(form.organization.profile).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::ProfileForm)
          expect(form.organization.profile.inbox).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::InboxForm)
          expect(form.organization.profile.office_locations.first).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::OfficeLocationForm)
          expect(form.staff_roles.first).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm)
        end
      end

      context "profile_type = broker_agency" do

        it 'instantiates a new registration form for broker agency profile' do
          form = subject.for_new(profile_type:"broker_agency")
          expect(form.profile_type).to eq 'broker_agency'
          expect(form.profile_id).to eq nil
          expect(form.organization).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::OrganizationForm)
          expect(form.organization.profile.parent).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::OrganizationForm)
          expect(form.organization.profile).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::ProfileForm)
          expect(form.organization.profile.inbox).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::InboxForm)
          expect(form.organization.profile.office_locations.first).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::OfficeLocationForm)
          expect(form.staff_roles.first).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm)
          expect(form.organization.profile.language_options.first).to be_an_instance_of(LanguageList::LanguageInfo)
        end
      end
    end
  end
end
