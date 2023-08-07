# frozen_string_literal: true

require 'rails_helper'

describe Effective::Datatables::NoticesDatatable, "verifying access" do
  let(:current_user) do
    double('User', person: person)
  end

  let(:person) { double('Person', hbx_staff_role: double('HbxStaffRole', permission: permission)) }

  let(:permission) { double('Permission', can_view_notice_templates: can_view_notice_templates) }

  subject { Effective::Datatables::NoticesDatatable.new({id: 'test_id'}) }

  context 'without permissions' do
    let(:can_view_notice_templates) { false }

    it 'denies user' do
      expect(subject.authorized?(current_user, nil, nil, nil)).to be_falsey
    end
  end

  context 'with permissions' do
    let(:can_view_notice_templates) { true }

    it 'allows user' do
      expect(subject.authorized?(current_user, nil, nil, nil)).to be_truthy
    end
  end
end
