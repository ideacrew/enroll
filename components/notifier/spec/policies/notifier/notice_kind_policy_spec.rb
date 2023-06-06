# frozen_string_literal: true

describe Notifier::NoticeKindPolicy, dbclean: :after_each do
  # let(:primary_person_id) { double }
  let(:notice_kind) { instance_double(::Notifier::NoticeKind) }
  let(:user) do
    double('User', person: person)
  end

  let(:person) { double('Person', hbx_staff_role: double('HbxStaffRole', permission: permission)) }

  let(:permission) { double('Permission', can_view_notice_templates: can_view_notice_templates, can_edit_notice_templates: can_edit_notice_templates) }

  subject { Notifier::NoticeKindPolicy.new(user, notice_kind) }

  context 'without permissions' do
    let(:can_view_notice_templates) { false }
    let(:can_edit_notice_templates) { false }

    it "can't index" do
      expect(subject.index?).to be_falsey
    end

    it "can't edit" do
      expect(subject.edit?).to be_falsey
    end
  end

  context 'with permissions' do
    context 'with only read permissions' do
      let(:can_view_notice_templates) { true }
      let(:can_edit_notice_templates) { false }

      it "can index" do
        expect(subject.index?).to be_truthy
      end

      it "can't edit" do
        expect(subject.edit?).to be_falsey
      end
    end

    context 'with only read and write permissions' do
      let(:can_view_notice_templates) { true }
      let(:can_edit_notice_templates) { true }

      it "can index" do
        expect(subject.index?).to be_truthy
      end

      it "can edit" do
        expect(subject.edit?).to be_truthy
      end
    end
  end
end
