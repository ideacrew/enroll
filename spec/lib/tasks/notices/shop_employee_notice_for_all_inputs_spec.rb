require 'rails_helper'
Rake.application.rake_require "tasks/notices/shop_employee_notice_for_all_inputs"
Rake::Task.define_task(:environment)

RSpec.describe 'Generate notices to employee by taking hbx_ids, census_ids and event name', :type => :task, dbclean: :after_each do
  let!(:employer_profile) { census_employee_2.employer_profile}
  let(:person) { FactoryBot.create(:person)}
  let!(:employee_role) { emp_role = FactoryBot.create(:employee_role, person: person, employer_profile: employer_profile)
                         emp_role.update_attributes(census_employee: census_employee)
                         emp_role}
  let!(:census_employee) { FactoryBot.create(:census_employee, employer_profile: employer_profile) }

  let(:person2) { FactoryBot.create(:person)}
  let!(:employee_role_2) { emp_role = FactoryBot.create(:employee_role, person: person2, employer_profile: employer_profile)
                           emp_role.update_attributes(census_employee: census_employee)
                           emp_role}
  let!(:census_employee_2) { FactoryBot.create(:census_employee) }

  before :each do
    $stdout = StringIO.new
    ActiveJob::Base.queue_adapter = :test
    ENV['event'] = nil
    ENV['employee_ids'] = nil
    ENV['hbx_ids'] = nil
  end

  after(:each) do
    $stdout = STDOUT
    Rake::Task['notice:shop_employee_notice_event'].reenable
  end

  context "Trigger Notice to employees", dbclean: :after_each do
    it "when multiple hbx_ids input is given should trigger twice" do
      ENV['event'] = "rspec-event"
      ENV['hbx_ids'] = "#{person.hbx_id} #{person2.hbx_id}"
      Rake::Task['notice:shop_employee_notice_event'].invoke
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq 2
      expect($stdout.string).to match(/Notice Triggered Successfully/)
    end

    it "should not trigger notice" do
      ENV['event'] = nil
      Rake::Task['notice:shop_employee_notice_event'].invoke(hbx_ids: '1231 131323')
      expect($stdout.string).to match(/Please specify the type of event name/)
    end

    it "when census_employee_id(s) are given" do
      ENV['event'] = "rspec-event"
      census_employee_role_id = census_employee.id.to_s
      census_employee_2_rol_id = census_employee_2.id.to_s
      ENV['employee_ids'] = "#{census_employee_role_id} #{census_employee_2_rol_id}"
      Rake::Task['notice:shop_employee_notice_event'].invoke(employee_ids: "#{census_employee_role_id} #{census_employee_2_rol_id}", event: "rspec-event")
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq 2
    end

    it "should trigger only once when one employee_id and one hbx_ids are given" do
      ENV['event'] = "rspec-event"
      ENV['employee_ids'] = "#{census_employee.id.to_s}"
      ENV['hbx_ids'] = "#{person.hbx_id}"
      person_hbx_id =  "#{person.hbx_id}"
      census_id = "#{census_employee.id.to_s}"
      allow(EmployerProfile).to receive(:find).with("987").and_return(employer_profile)
      Rake::Task['notice:shop_employee_notice_event'].invoke(employee_ids: census_id, hbx_ids:person_hbx_id, event: "rpsec-event")
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq 1
    end
  end

end
