# frozen_string_literal: true

require 'domain/operations/families/member_params_context'

RSpec.describe Operations::Families::UpdateMember, type: :model, dbclean: :after_each do
  include_context 'member_attributes_context'

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
    Operations::Families::CreateMember.new.call({member_params: member_hash, family_id: family.id})
    family.reload
  end

  let(:dependent) { family.family_members.where(is_primary_applicant: false).last.person }

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context '#update member' do
    context 'success' do

      context '- when person attributes are changed
               - when active vlp document attributes are changed' do
        let(:params) do
          member_hash.merge!(gender: 'female', is_incarcerated: false, :ethnicity => ["Filipino", "Japanese", "Korean", "Vietnamese", "Other Asian"], relationship: 'child')
          member_hash[:consumer_role][:immigration_documents_attributes][0].merge!(i94_number: '45612378985')
          member_hash
        end

        before do
          @result = subject.call({member_params: params, family_id: family.id, person_hbx_id: dependent.hbx_id})
          family.reload
          @person = Person.by_hbx_id(member_hash[:hbx_id]).first
        end

        it 'returns a success result' do
          expect(@result).to be_a(Dry::Monads::Result::Success)
        end

        it 'persists the person' do
          expect(@person.persisted?).to be_truthy
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

        it 'update relationship' do
          expect(family.primary_person.person_relationships.count).to eq 1
          expect(family.primary_person.person_relationships.first.relative_id).to eq @person.id
          expect(family.primary_person.person_relationships.first.kind).to eq 'child'
        end
      end

      context '- when person attributes are changed
               - when vlp document type is changed' do
        let(:params) do
          member_hash[:consumer_role][:immigration_documents_attributes][0].merge!(subject: 'I-571 (Refugee Travel Document)', i94_number: '45612378985')
          member_hash
        end
        before do
          @result = subject.call({member_params: params, family_id: family.id, person_hbx_id: dependent.hbx_id})
          family.reload
          @person = Person.by_hbx_id(member_hash[:hbx_id]).first
        end

        it 'returns a success result' do
          expect(@result).to be_a(Dry::Monads::Result::Success)
        end

        it 'new active vlp document' do
          expect(@person.consumer_role.active_vlp_document.subject).to eq 'I-571 (Refugee Travel Document)'
        end

        it 'previous VLP document is inactive' do
          inactive_vlp_document = @person.consumer_role.vlp_documents.where(subject: 'I-94 (Arrival/Departure Record)').first
          expect(@person.consumer_role.active_vlp_document.id).not_to eq inactive_vlp_document.id
          expect(@person.consumer_role.vlp_documents.count).to eq 2
        end
      end
    end

    context 'failure' do
      let(:params) do
        member_hash.merge!(gender: 'female', is_incarcerated: false, :ethnicity => ["Filipino", "Japanese", "Korean", "Vietnamese", "Other Asian"])
        member_hash[:consumer_role][:immigration_documents_attributes][0].merge!(i94_number: '45612378985')
        member_hash
      end

      before do
        @result = subject.call({member_params: params, person_hbx_id: dependent.hbx_id})
        family.reload
        @person = Person.by_hbx_id(member_hash[:hbx_id]).first
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
