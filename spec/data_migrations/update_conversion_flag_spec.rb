require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_conversion_flag")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

class AcaHelperModStubber
  extend Config::AcaHelper
end

describe UpdateConversionFlag, :dbclean => :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:employer_profile) {abc_profile}
  let(:given_task_name) { "update_conversion_flag" }
  subject { UpdateConversionFlag.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating conversion flag of employer" do

    it "should update profile source to self_serve and should approve employer attestation" do
      ClimateControl.modify fein: employer_profile.fein, source_kind: 'self_serve' do
        subject.migrate
      end
      employer_profile.reload
      expect(employer_profile.profile_source).to eq :self_serve
      expect(employer_profile.employer_attestation.aasm_state).to eq "approved" if AcaHelperModStubber.employer_attestation_is_enabled?
    end

    it "should update profile source to conversion and approve employer attestation" do
      ClimateControl.modify fein: employer_profile.fein, source_kind: 'conversion' do
        subject.migrate
      end
      employer_profile.active_benefit_sponsorship.reload
      expect(employer_profile.profile_source).to eq :conversion
      expect(employer_profile.employer_attestation.aasm_state).to eq "approved" if AcaHelperModStubber.employer_attestation_is_enabled?
    end
  end

  if AcaHelperModStubber.employer_attestation_is_enabled?
    describe "employer with denied employer attestation" do
      let(:attestation) { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: 'denied', benefit_sponsorship: employer_profile.active_benefit_sponsorship) }
      let(:document) { BenefitSponsors::Documents::EmployerAttestationDocument.new(aasm_state: 'rejected', employer_attestation: attestation) }

      it "should approve employer attestation" do
        expect(attestation.aasm_state).to eq 'denied'
        ClimateControl.modify fein: employer_profile.fein, source_kind: 'self_serve' do
          subject.migrate
        end
        employer_profile.reload
        expect(employer_profile.profile_source).to eq :self_serve
        expect(employer_profile.employer_attestation.aasm_state).to eq "approved"
      end
    end

    describe "employer with rejected employer attestation document" do
      let(:employer_attestation) { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: 'denied', benefit_sponsorship: employer_profile.active_benefit_sponsorship) }
      let(:document) { BenefitSponsors::Documents::EmployerAttestationDocument.new(aasm_state: 'submitted', employer_attestation: employer_attestation) }

      it "should accept the employer attested document" do
        ClimateControl.modify fein: employer_profile.fein, source_kind: 'self_serve' do
          expect(employer_attestation.aasm_state).to eq "denied"
          subject.migrate
        end
        employer_profile.reload
        expect(document.aasm_state).to eq "submitted"
      end
    end
  end
end
