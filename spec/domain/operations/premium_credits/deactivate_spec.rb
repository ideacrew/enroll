# frozen_string_literal: true

RSpec.describe Operations::PremiumCredits::Deactivate, type: :model, dbclean: :after_each do
  let(:person) do
    FactoryBot.create(:person,
                      :with_consumer_role,
                      :with_active_consumer_role,
                      hbx_id: '1179388',
                      last_name: 'Eric',
                      first_name: 'Pierpont',
                      dob: '1984-05-22')
  end

  let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:start_of_month) { TimeKeeper.date_of_record.beginning_of_month }

  let(:result) { subject.call({ family: family, new_effective_date: start_of_month }) }

  context 'with an existing GroupPremiumCredit' do
    let!(:group_premium_credit) do
      FactoryBot.create(:group_premium_credit,
                        authority_determination_id: BSON::ObjectId.new,
                        authority_determination_class: 'FinancialAssistance::Application',
                        family: family)
    end

    it 'should end date the group_premium_credit' do
      expect(result.success).to eq(
        "Deactivated all the Active aptc_csr Group Premium Credits for given family with hbx_id: #{family.hbx_assigned_id}"
      )
      expect(group_premium_credit.reload.end_on).to eq(start_of_month)
    end
  end

  context 'without any GroupPremiumCredits' do
    it 'should return a failure with errors' do
      expect(result.success).to eq('No Active Group Premium Credits to deactivate')
    end
  end

  # rubocop:disable Lint/EmptyBlock
  context 'with invalid params' do
    let(:family) {}
    let(:new_effective_date) {}

    it 'should return a failure with error message' do
      expect(result.failure).to eq(
        'Invalid params. family should be an instance of Family and new_effective_date should be an instance of Date'
      )
    end
  end
  # rubocop:enable Lint/EmptyBlock
end
