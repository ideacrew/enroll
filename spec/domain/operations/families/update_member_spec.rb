# frozen_string_literal: true

require 'domain/operations/financial_assistance/applicant_params_context'

RSpec.describe Operations::Families::CreateOrUpdateMember, type: :model, dbclean: :after_each do
  include_context 'export_applicant_attributes_context'

  let(:person) do
    FactoryBot.create(:person,
                      :with_consumer_role,
                      :with_active_consumer_role,
                      hbx_id: '20944967',
                      last_name: 'primary_first',
                      first_name: 'primary_last',
                      ssn: '243108282',
                      dob: Date.new(1984, 3, 8))
  end

  let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:create_spouse) do
    Operations::Families::CreateMember.new.call({applicant_params: applicant_params.merge(relationship: 'spouse'), family_id: family.id})
    family.reload
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context '#update member' do
    let(:params) do
      applicant_params.merge(family_id: family.id, gender: 'female', is_incarcerated: false, :ethnicity => ["Filipino", "Japanese", "Korean", "Vietnamese", "Other Asian"], i94_number: '45612378985', relationship: 'spouse')
    end

    context 'success' do
      before do
        @result = subject.call(params)
        family.reload
        @person = Person.by_hbx_id(params[:person_hbx_id]).first
      end

      it 'returns a success result' do
        expect(@result).to be_a(Dry::Monads::Result::Success)
      end

      it 'persists the person' do
        expect(@person.persisted?).to be_truthy
      end

      it 'update person' do
        expect(@person).not_to be_nil
      end

      it 'no change in family member count' do
        expect(family.family_members.count).to eq(2)
      end

      it 'update person attributes' do
        expect(@person.is_incarcerated).to be_falsey
        expect(@person.gender).to eq 'female'
        expect(@person.ethnicity).to eq ["Filipino", "Japanese", "Korean", "Vietnamese", "Other Asian"]
      end

      it 'update VLP document attributes' do
        expect(@person.consumer_role.active_vlp_document.i94_number).to eq '45612378985'
      end
    end

    context 'failure' do
      before do
        @result = subject.call(params.except(:family_id))
        family.reload
        @person = Person.by_hbx_id(params[:person_hbx_id]).first
      end

      it 'should return failure' do
        expect(@result).to be_a Dry::Monads::Result::Failure
      end

      it 'should not create person' do
        expect(@person).not_to be_nil
      end

      it 'should not create family member' do
        expect(family.family_members.count).to eq 2
      end
    end
  end
end
