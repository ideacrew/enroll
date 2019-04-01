require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_book_mark_url_for_employee_role")

describe UpdateBookMarkUrlForEmployeerole, dbclean: :after_each do

  let(:given_task_name) { "update_book_mark_url_for_employee_role" }
  subject { UpdateBookMarkUrlForEmployeerole.new(given_task_name, double(:current_scope => nil)) }

   after :each do
    ["employee_role_id", "bookmark_url"].each do |env_variable|
      ENV[env_variable] = nil
    end
  end

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update bookmark url" do

    let(:person) { FactoryBot.create(:person, :with_ssn, :with_employee_role)}
    let(:employee_role) {person.employee_roles.first}

    before(:each) do
      ENV["employee_role_id"] = employee_role.id.to_s
      ENV["bookmark_url"] = "https://enroll.dchealthlink.com/families/home"
    end

    it "should update bookmark url associated with employee role" do
      subject.migrate
      expect(employee_role.reload.bookmark_url).to eq "https://enroll.dchealthlink.com/families/home"
    end
  end
end

