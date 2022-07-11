# frozen_string_literal: true

RSpec.describe Operations::PremiumCredits::Build, type: :model, dbclean: :after_each do
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

  let(:params) do
    {
      family: family,
      gpc_params: {
        kind: "aptc_csr",
        authority_determination_id: BSON::ObjectId.new,
        authority_determination_class: "FinancialAssistance::Application",
        premium_credit_monthly_cap: 317.0,
        sub_group_id: BSON::ObjectId.new,
        sub_group_class: "FinancialAssistance::EligibilityDetermination",
        start_on: start_of_month,
        member_premium_credits: [
          { kind: "aptc_eligible", value: "true", start_on: start_of_month, family_member_id: family.primary_applicant.id },
          { kind: "csr", value: "73", start_on: start_of_month, family_member_id: family.primary_applicant.id }
        ]
      }
    }
  end

  let(:result) { subject.call(params) }

  context 'with valid input params' do
    it 'should return a family with a group_premium_credit and member_premium_credits' do
      gpc = result.success.group_premium_credits.first
      expect(gpc).to be_a(GroupPremiumCredit)
      expect(gpc.member_premium_credits.size).to eq(2)
      expect(gpc.member_premium_credits.first).to be_a(MemberPremiumCredit)
    end
  end

  context 'with invalid kind for group_premium_credit' do
    before { params[:gpc_params][:kind] = 'kind' }

    it 'should return a failure with errors' do
      expect(result.failure.errors.to_h).to eq(
        { kind: ['must be one of: aptc_csr'] }
      )
    end
  end

  context 'with bad params' do
    before { params[:family] = 'family' }

    it 'should return a failure with errors' do
      expect(result.failure).to eq(
        'Invalid params. family should be an instance of Family'
      )
    end
  end
end
