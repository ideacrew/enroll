# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupPremiumCredit, type: :model do
  let(:person)  { FactoryBot.create(:person, :with_consumer_role) }
  let(:family)  { FactoryBot.create(:family, :with_primary_family_member, person: person) }

  let(:params) do
    { kind: 'aptc_csr',
      start_on: TimeKeeper.date_of_record }
  end

  describe 'initialize' do
    subject { described_class.new(input_params) }

    context 'valid params' do
      let(:input_params) { params }

      it 'should be valid' do
        expect(subject.valid?).to be_truthy
      end
    end

    context 'invalid kind' do
      let(:input_params) { params.merge({ kind: 'test' }) }

      it 'should be valid' do
        subject.valid?
        expect(subject.errors.full_messages).to include('Kind test is not a valid group premium credit kind')
      end
    end

    context 'invalid kind' do
      let(:input_params) { params.merge({ end_on: TimeKeeper.date_of_record - 1.day }) }

      it 'should be valid' do
        subject.valid?
        expect(subject.errors.full_messages).to include("end_on: #{input_params[:end_on]} cannot occur before start_on: #{input_params[:start_on]}")
      end
    end
  end

  describe 'authority_determination' do
    let(:group_pc) do
      FactoryBot.create(:group_premium_credit,
                        authority_determination_id: application.id,
                        authority_determination_class: application.class.to_s,
                        family: family)
    end

    context 'valid authority_determination' do
      let(:application) do
        FactoryBot.create(:application,
                          family_id: family.id,
                          aasm_state: 'draft',
                          assistance_year: TimeKeeper.date_of_record.year,
                          effective_date: Date.today)
      end

      it 'should return an instance of FinancialAssistance::Application' do
        expect(group_pc.authority_determination).to be_a FinancialAssistance::Application
      end
    end

    context 'invalid authority_determination_class' do
      let(:application) do
        double(id: BSON::ObjectId.new, class: 'DummyTest')
      end

      it 'should return nil as the class name is invalid' do
        expect(group_pc.authority_determination).to be_nil
      end
    end

    context 'invalid authority_determination_id' do
      let(:application) do
        double(id: 'application_id', class: 'FinancialAssistance::Application')
      end

      it 'should return nil as the authority_determination_id is invalid' do
        expect(group_pc.authority_determination).to be_nil
      end
    end
  end

  describe 'sub_group' do
    let(:group_pc) do
      FactoryBot.create(:group_premium_credit,
                        authority_determination_id: application.id,
                        authority_determination_class: application.class.to_s,
                        sub_group_id: eligibility_determination.id,
                        sub_group_class: eligibility_determination.class.to_s,
                        family: family)
    end

    let(:application) do
      FactoryBot.create(:application,
                        family_id: family.id,
                        aasm_state: 'draft',
                        assistance_year: TimeKeeper.date_of_record.year,
                        effective_date: Date.today)
    end

    context 'valid sub_group' do
      let(:eligibility_determination) do
        FactoryBot.create(:financial_assistance_eligibility_determination,
                          application: application,
                          max_aptc: 300.00)
      end

      it 'should return an instance of FinancialAssistance::Application' do
        expect(group_pc.sub_group).to be_a FinancialAssistance::EligibilityDetermination
      end
    end

    context 'invalid sub_group_class' do
      let(:eligibility_determination) do
        double(id: BSON::ObjectId.new, class: 'DummyTest')
      end

      it 'should return nil as the class name is invalid' do
        expect(group_pc.sub_group).to be_nil
      end
    end

    context 'invalid sub_group_id' do
      let(:eligibility_determination) do
        double(id: 'eligibility_determination_id', class: 'FinancialAssistance::EligibilityDetermination')
      end

      it 'should return nil as the sub_group_id is invalid' do
        expect(group_pc.sub_group).to be_nil
      end
    end
  end

end
