# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Forms::Applicant, type: :model, dbclean: :after_each do
  let!(:application) do
    FactoryBot.create(:application,
                      family_id: BSON::ObjectId.new,
                      aasm_state: 'draft',
                      effective_date: Date.today)
  end

  let!(:applicant) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: Date.today - 40.years,
                      is_primary_applicant: true,
                      family_member_id: BSON::ObjectId.new)
  end

  let!(:spouse_applicant) do
    appl = FactoryBot.create(:applicant,
                             application: application,
                             dob: Date.today - 40.years,
                             family_member_id: BSON::ObjectId.new)
    application.ensure_relationship_with_primary(appl, 'spouse')
    appl
  end

  let(:params) do
    { first_name: input_applicant.first_name,
      last_name: input_applicant.last_name,
      middle_name: '',
      name_sfx: '',
      dob: input_applicant.dob.strftime("%Y-%m-%d"),
      ssn: input_applicant.ssn,
      gender: input_applicant.gender,
      is_applying_coverage: 'true',
      us_citizen: 'true',
      naturalized_citizen: 'false',
      indian_tribe_member: 'false',
      tribal_id: '',
      is_incarcerated: 'false',
      relationship: relationship,
      is_consumer_role: 'true',
      is_temporarily_out_of_state: '0',
      is_homeless: '0',
      no_ssn: '0',
      addresses_attributes: { :'0' => { kind: 'home',
                                        address_1: '',
                                        address_2: '',
                                        city: '',
                                        state: '',
                                        zip: '',
                                        _destroy: 'false'},
                              :'1' => { kind: 'mailing',
                                        address_1: '',
                                        address_2: '',
                                        city: '',
                                        state: '',
                                        zip: '',
                                        _destroy: 'false'}},
      ethnicity: ['', '', '', '', '', '', '']}
  end

  context 'relationship_validation' do

    before do
      @applicant_form = described_class.new(params)
      @applicant_form.application_id = application.id
      @applicant_form.applicant_id = input_applicant.id
      @applicant_form.relationship_validation
    end

    context 'applicant spouse update' do
      let(:input_applicant) {spouse_applicant}
      let(:relationship) {'spouse'}

      it 'should not add any errors when checked for validation errors' do
        expect(@applicant_form.errors.full_messages).to be_empty
      end
    end

    context 'with spouse and child as spouse' do
      let!(:child_applicant) do
        appl = FactoryBot.create(:applicant,
                                 application: application,
                                 dob: Date.today - 40.years,
                                 family_member_id: BSON::ObjectId.new)
        application.ensure_relationship_with_primary(appl, 'child')
        appl
      end

      let(:input_applicant) {child_applicant}
      let(:relationship) {'spouse'}

      it 'should add error when checked for validation errors' do
        expect(@applicant_form.errors.full_messages).to include('can not have multiple spouse or life partner')
      end
    end

    context 'with more than one spouse' do
      let!(:spouse_applicant2) do
        appl = FactoryBot.create(:applicant,
                                 application: application,
                                 dob: Date.today - 40.years,
                                 family_member_id: BSON::ObjectId.new)
        application.ensure_relationship_with_primary(appl, 'spouse')
        appl
      end

      let(:input_applicant) {spouse_applicant2}
      let(:relationship) {'spouse'}

      it 'should add error when checked for validation errors' do
        expect(@applicant_form.errors.full_messages).to include('can not have multiple spouse or life partner')
      end
    end
  end

  describe "ssn is missing" do
    let!(:application2) { FactoryBot.create(:financial_assistance_application, family_id: BSON::ObjectId.new) }
    let!(:other_applicant) { FactoryBot.create(:financial_assistance_applicant, application: application2, ssn: '889984400', family_member_id: BSON::ObjectId.new, is_primary_applicant: true) }
    let!(:child_applicant) { FactoryBot.create(:financial_assistance_applicant, application: application, dob: Date.today - 40.years, family_member_id: BSON::ObjectId.new) }
    let(:input_applicant) {child_applicant}
    let(:relationship) {'child'}
    before do
      allow_any_instance_of(described_class).to receive(:relationship_validation).and_return(nil)
      @applicant_form = described_class.new(params.merge!(first_name: "Test", last_name: "User", gender: "male", same_with_primary: false))
      @applicant_form.save
    end

    it "form should contain error" do
      expect(@applicant_form.errors.full_messages).to include('ssn is missing')
    end
  end


  context 'check_same_ssn' do
    context 'applicant child update with same ssn' do
      let!(:application2) { FactoryBot.create(:financial_assistance_application, family_id: BSON::ObjectId.new) }
      let!(:other_applicant) { FactoryBot.create(:financial_assistance_applicant, application: application2, ssn: '889984400', family_member_id: BSON::ObjectId.new) }
      let!(:child_applicant) { FactoryBot.create(:financial_assistance_applicant, application: application, dob: Date.today - 40.years, family_member_id: BSON::ObjectId.new) }

      before do
        @applicant_form = described_class.new(params.except(:ssn).merge({ssn: '889984400'}))
        @applicant_form.application_id = application.id
        @applicant_form.applicant_id = input_applicant.id
        @applicant_form.relationship_validation
        @applicant_form.check_same_ssn
      end

      let(:input_applicant) {child_applicant}
      let(:relationship) {'child'}

      it 'should add error when ssn is matching' do
        expect(@applicant_form.errors.full_messages).to include('ssn is already taken')
      end
    end

    context 'when single applicant in the application' do
      let!(:application2) { FactoryBot.create(:financial_assistance_application, family_id: BSON::ObjectId.new) }
      let!(:other_applicant) { FactoryBot.create(:financial_assistance_applicant, application: application2, ssn: '889984400', family_member_id: BSON::ObjectId.new, dob: Date.today - 40.years) }

      let(:params2) do
        { first_name: other_applicant.first_name,
          last_name: other_applicant.last_name,
          middle_name: '',
          name_sfx: '',
          dob: other_applicant.dob.strftime("%Y-%m-%d"),
          ssn: other_applicant.ssn,
          gender: other_applicant.gender,
          is_applying_coverage: 'true',
          us_citizen: 'true',
          naturalized_citizen: 'false',
          indian_tribe_member: 'false',
          tribal_id: '',
          is_incarcerated: 'false',
          relationship: "self",
          is_consumer_role: 'true',
          is_temporarily_out_of_state: '0',
          is_homeless: '0',
          no_ssn: '0',
          addresses_attributes: { :'0' => { kind: 'home',
                                            address_1: '',
                                            address_2: '',
                                            city: '',
                                            state: '',
                                            zip: '',
                                            _destroy: 'false'},
                                  :'1' => { kind: 'mailing',
                                            address_1: '',
                                            address_2: '',
                                            city: '',
                                            state: '',
                                            zip: '',
                                            _destroy: 'false'}},
          ethnicity: ['', '', '', '', '', '', '']}
      end

      before do
        @applicant_form = described_class.new(params2)
        @applicant_form.application_id = application2.id
        @applicant_form.applicant_id = other_applicant.id
        @applicant_form.check_same_ssn
      end

      it 'should not throw 502 error' do
        expect(@applicant_form.errors.full_messages.present?).to be_falsey
      end
    end
  end
end
