# frozen_string_literal: true

require 'rails_helper'

describe Effective::Datatables::EmployerDatatable, dbclean: :after_each do

  describe '#authorized?' do
    context 'when current user does not exist' do
      let(:user) { nil }

      it 'should not authorize access' do
        expect(subject.authorized?(user, nil, nil, nil)).to eq(false)
      end
    end

    context 'when current user exists without staff role' do
      let(:user) { FactoryBot.create(:user) }

      it 'should not authorize access' do
        expect(subject.authorized?(user, nil, nil, nil)).to be_falsey
      end
    end

    context 'when current user exists with staff role' do
      let(:person) {FactoryBot.create(:person, :with_hbx_staff_role)}
      let(:user) { FactoryBot.create(:user, person: person, roles: ["hbx_staff"]) }

      it 'should authorize access' do
        expect(subject.authorized?(user, nil, nil, nil)).to be_truthy
      end
    end
  end
end
