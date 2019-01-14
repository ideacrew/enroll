require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_qle_tooltip")

describe UpdateQleTooltip, dbclean: :after_each do
  let(:given_task_name) { "update_qle_tooltip" }
  subject { UpdateQleTooltip.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "remove the plans of specific carrier for an er " do
    let(:qle){ FactoryBot.create(:qualifying_life_event_kind, :title => "Entered into a legal domestic partnership", :tool_tip =>'Entering a domestic partnership as permitted or recognized by the District of Columbia') }
    before(:each) do
      allow(ENV).to receive(:[]).with('title').and_return("Entered into a legal domestic partnership")
      allow(ENV).to receive(:[]).with('text').and_return("Entering a domestic partnership as permitted or recognized by Massachusetts")
    end
    
    it "should update tooltip" do
      expect(qle.tool_tip).to eq "Entering a domestic partnership as permitted or recognized by the District of Columbia"
      subject.migrate
      qle.reload
      expect(qle.tool_tip).to eq "Entering a domestic partnership as permitted or recognized by Massachusetts"
    end
  end
end
