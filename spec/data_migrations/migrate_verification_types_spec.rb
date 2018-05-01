require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "migrate_verification_types")
describe MigrateVerificationTypes, dbclean: :after_each do
  let(:given_task_name) { "move_all_verification_types_to_model" }
  let(:person) {FactoryGirl.create(:person, :with_consumer_role)}
  let(:vlp_doc) {FactoryGirl.build(:vlp_document)}
  subject { MigrateVerificationTypes.new(given_task_name, double(:current_scope => nil)) }

  shared_examples_for "verification types migrations" do |types_count, ssn, tribal_id, us_citizen, correct_type, wrong_type|
    before :each do
      allow(subject).to receive(:get_people).and_return [person]
      allow(person).to receive(:ssn).and_return ssn
      allow(person).to receive(:tribal_id).and_return tribal_id
      allow(person).to receive(:us_citizen).and_return us_citizen
      subject.migrate
      person.reload
    end
    it "assigns correct number of verification types" do
      expect(person.verification_types.active.count).to eq types_count.to_i
    end
    it "assigns #{correct_type} vetification_type" do
      expect(person.verification_types.active.select{|type| type.type_name == correct_type}.present?).to be_truthy
    end
    it "doesn't assign #{wrong_type} type" do
      expect(person.verification_types.active.select{|type| type.type_name == wrong_type}.present?).to be_falsey
    end
  end

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "dynamic types migration to model" do
    it_behaves_like "verification types migrations", "4", "343555664", "454334556", true, 'Citizenship', 'Immigration status', "vlp_doc"
    it_behaves_like "verification types migrations", "4", "343555664", "454334556", true, 'Social Security Number', 'Immigration status'
    it_behaves_like "verification types migrations", "4", "343555664", "454334556", true, 'DC Residency', 'Immigration status'
    it_behaves_like "verification types migrations", "4", "343555664", "454334556", true, 'American Indian Status', 'Immigration status'
    it_behaves_like "verification types migrations", "3", "343555664", nil, true, 'Citizenship', 'American Indian Status', "vlp_doc"
    it_behaves_like "verification types migrations", "2", nil, nil, true, 'Citizenship', 'Social Security Number', "vlp_doc"
  end

  describe "vlp documents migration" do
    before do
      person.consumer_role.vlp_documents.first.verification_type = "Citizenship"
      person.save!
      subject.migrate
      person.reload
    end

    it "migrate Citizenship document" do
      expect(person.verification_types.active.where(:type_name => "Citizenship").first.vlp_documents.count).to eq 1
    end
  end
end