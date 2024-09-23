# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Orms::Mongoid::DomainModel do
  context 'when a Mongoid::Document model class includes the DomainModel mixin' do
    let(:account_klass) { Person }

    # it 'then the class responds to the #reference_associations class method' do
    #   expect(account_klass).to respond_to :reference_associations
    # end

    context 'when a new instance of the class is initialized' do
      it 'then the class is initialized with a new instance of the class' do
        expect(account_klass.new).to be_a_new(account_klass)
      end

    #   it 'then the class responds to the #deep_serializable_hash instance method' do
    #     expect(account_klass.new).to respond_to :deep_serializable_hash
    #   end

    #   it 'then the class responds to the #entity_klass instance method' do
    #     expect(account_klass.new).to respond_to :entity_klass
    #   end

    #   it 'then the class responds to the #contract_klass instance method' do
    #     expect(account_klass.new).to respond_to :contract_klass
    #   end

    #   it 'then the class responds to the #to_entity instance method' do
    #     expect(account_klass.new).to respond_to :to_entity
    #   end

      it 'then the class responds to the #to_hash instance method' do
        expect(account_klass.new).to respond_to :to_hash
      end

    #   it 'then the class responds to the #persist instance method' do
    #     expect(account_klass.new).to respond_to :persist
    #   end
    end
  end

  describe '.reference_associations' do
    let(:account_klass) { Person }

    # let(:authorization_role_relation_key) { 'authorization_roles' }
    # let(:journal_entry_relation_key) { 'journal_entries' }
    # let(:has_many_association_klass) { Mongoid::Association::Referenced::HasMany }

    # # let(:expected_response) { [ a_hash_including(authorization_role_relation_key(Hash).and(include(some_important: :contract)) ] }

    # let(:expected_response) { [ "#{authorization_role_relation_key}": be_kind_of(Hash).and(include(some_important: :contract)) ] }
    # let(:expected_response) { [ huge_hash: be_kind_of(Hash).and(include(some_important: :contract)) ] }
    # let(:expected_response) { [ huge_hash: be_kind_of(Hash).and(include(some_important: :contract)) ] }

    # it { expect(account_klass.reference_associations).to(match(expected_response)) }

    # it 'returns a hash of reference associations' do
    #   require 'pry'
    #   binding.pry

    #   expect(account_klass.reference_associations).to match_array([
    #     a_hash_including('authorization_roles' => have_attributes(class: Mongoid::Association::Referenced::HasMany, owner_class: 'Accounts::AuthorizationRole')),
    #     a_hash_including('journal_entries'  => have_attributes(class: Mongoid::Association::Referenced::HasMany, owner_class: 'Accounts::AuthorizationRole'))
    # ]
    #   )

    #   expect(account_klass.reference_associations).to match(
    #     [
    #       a_hash_including(authorization_role_relation_key => be_kind_of(Mongoid::Association::Referenced::HasMany)),
    #       a_hash_including(journal_entry_relation_key => be_kind_of(Mongoid::Association::Referenced::HasMany))
    #     ]
    #   )

    # it 'with a referenced association for authorization_roles' do
    #   expect(
    #     account_klass.reference_associations[authorization_role_relation_key]
    #   ).to be_a Mongoid::Association::Referenced::HasMany
    # end
  end

  context 'when reference associations are defined' do
    subject(:account) { account_klass.new }

    let(:account_klass) { Person }

    let(:authorization_role_klass) { Person }
    let(:authorization_role_relation_key) { 'authorization_roles' }
    let!(:authorization_role_params) { Array.new(4) { authorization_role_klass.create!(account: account) } }

    # Array.new(4) { authorization_role_klass.new } }
    # let(:authorization_role_params) do
    #   [
    #     authorization_role_klass.create(role: 'consumer', description: 'consumer level privileges'),
    #     authorization_role_klass.create(role: 'broker', description: 'broker level privileges'),
    #     authorization_role_klass.create(role: 'employer', description: 'employer level privileges'),
    #     authorization_role_klass.create(role: 'admin', description: 'admin level privileges')
    #   ]
    # end

    let(:journal_entry_klass) { Person }
    let(:journal_entry_relation_key) { 'journal_entries' }
    let!(:journal_entry_params) { Array.new(3) { journal_entry_klass.create!(account: account) } }
    # let(:journal_entry_params) do
    #   [
    #     journal_entry_klass.create(sequence_number: 0, reported_by: 'djt', start_on: Time.zone.today),
    #     journal_entry_klass.create(sequence_number: 1, reported_by: 'djt', start_on: Time.zone.today + 1.day),
    #     journal_entry_klass.create(sequence_number: 2, reported_by: 'djt', start_on: Time.zone.today + 2.days)
    #   ]
    # end

    let(:identity_klass) { Person }
    let!(:identity_params) { Array.new(3) { identity_klass.new(account: account) } }
    # let(:identity_params) do
    #   [
    #     identity_klass.new(provider: 'keycloak', uid: '100'),
    #     identity_klass.new(provider: 'keycloak', uid: '101'),
    #     identity_klass.new(provider: 'keycloak', uid: '102'),
    #     identity_klass.new(provider: 'keycloak', uid: '103')
    #   ]
    # end

#     let(:mister_magoo_profile_params) do
#       {
#         account: account,
#         email: Contacts::Email.new(kind: 'home', address: 'mister_magoo@example.com'),
#         mobile_phone: Contacts::Phone.from_us_phone_number('2025551212', kind: 'mobile'),
#         preferred_name: 'Mister Magoo',
#         locale: 'en'
#       }
#     end

#     let(:profile_klass) { Accounts::Profile }
#     let(:profile_params) { [profile_klass.new(mister_magoo_profile_params)] }

#     context 'when the model is persisted' do
#       # subject.save!

#       # subject(:created_account) { account_klass.first }
#       subject(:created_account) { account.save }

#       # before do
#       #   account_klass.create(
#       #     identities: identity_params,
#       #     profiles: profile_params,
#       #     authorization_roles: authorization_role_params,
#       #     journal_entries: journal_entry_params
#       #   )
#       # end

#       let!(:authorization_role_array) do
#         authorization_role_params.inject([]) do |role_hash_array, role_klass|
#           role_hash_array << role_klass.to_hash
#           # role_hash_array
#         end
#         # require 'pry', binding.pry
#       end

#       it 'then creates an Account' do
#         expect(account_klass.count).to eq 1
#       end

#       it 'then creates an embedded association and attributes for Identities' do
#         # expect(created_account.identities.count).to eq identity_params.count
#         expect(created_account.identities).to match_array(identity_params)
#       end

#       it 'then creates an embedded association and attributes for Profiles' do
#         expect(created_account.profiles).to eq profile_params
#       end

#       describe '#deep_serializable_hash' do
#         it 'then the serialized hash includes a key for the referenced authorization_role association' do
#           require 'pry'
#           binding.pry
#           expect(created_account.deep_serializable_hash.keys).to include authorization_role_relation_key
#         end

#         it 'then the deep_serialized_hash returns authorization_roles attributes and values' do
#           expect(created_account.deep_serializable_hash[authorization_role_relation_key]).to match_array(
#             authorization_role_array
#           )
#           # expect(created_account.deep_serializable_hash[authorization_role_relation_key]).to match(
#           #   [
#           #     a_hash_including('role' => 'admin', 'description' => 'admin level privileges'),
#           #     a_hash_including('role' => 'employer', 'description' => 'employer level privileges'),
#           #     a_hash_including('role' => 'broker', 'description' => 'broker level privileges'),
#           #     a_hash_including('role' => 'consumer', 'description' => 'consumer level privileges')
#           #   ]
#           # )
#         end

#         it 'then the deep_serialized_hash returns journal_entries attributes and values' do
#           expect(created_account.deep_serializable_hash[journal_entry_relation_key]).to match(
#             [
#               a_hash_including('sequence_number' => 0, 'reported_by' => 'djt'),
#               a_hash_including('sequence_number' => 1, 'reported_by' => 'djt'),
#               a_hash_including('sequence_number' => 2, 'reported_by' => 'djt')
#             ]
#           )
#         end

#         it 'then the serialized hash includes a key for the referenced journal_entry association' do
#           expect(created_account.deep_serializable_hash.keys).to include journal_entry_relation_key
#         end
#       end
#     end
  end
end