require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_hbx_id")

describe UpdateHbxId do
  let(:given_task_name) { "update_hbx_id" }
  subject { UpdateHbxId.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing hbx id within person records", db_clean: :before_each do
    
    let!(:person1) { FactoryBot.create(:person)}
    let!(:person2) { FactoryBot.create(:person)}
    let(:correct_hbxid) {person1.hbx_id}
    let(:incorrect_hbxid) {person2.hbx_id}

    it "should exchange hbx id " do
      ClimateControl.modify valid_hbxid: correct_hbxid, invalid_hbxid: incorrect_hbxid do 
        subject.migrate
        person2.reload
        expect(person2.hbx_id).to eq correct_hbxid
      end
    end

    it "should unset hbx id " do
      ClimateControl.modify valid_hbxid:correct_hbxid, invalid_hbxid:incorrect_hbxid do 
        subject.migrate
        person1.reload
        expect(person1.hbx_id).to eq nil
      end
    end

    it "should not exchange hbx id if any hbx_id is nil" do
      ClimateControl.modify valid_hbxid:'', invalid_hbxid:incorrect_hbxid do 
        subject.migrate
        person1.reload
        person2.reload
        expect(person1.hbx_id).to eq correct_hbxid
        expect(person2.hbx_id).to eq incorrect_hbxid
      end
    end
  end
end
