require 'rails_helper'

RSpec.shared_examples "a federal holiday" do |attributes|
  attributes.each do |attribute, value|
    it "should return #{value} from ##{attribute}" do
      expect(subject.send(attribute)).to eq(value)
    end
  end
end

RSpec.describe 'Load Federal Holidays Task', :type => :task do

  context "scheduled_event:update_federal_holidays" do
    before :all do
      Rake.application.rake_require "tasks/migrations/load_federal_holidays"
      Rake::Task.define_task(:environment)
    end

    before :context do
      invoke_task
    end

    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Independence Day') }
      it_should_behave_like "a federal holiday", { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: "Tue, 04 Jul 2017".to_date
                                                }
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Martin Luthor Bday') }
      it_should_behave_like "a federal holiday", { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: "Mon, 16 Jan 2017".to_date
                                                }
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Washington Bday') }
      it_should_behave_like "a federal holiday", { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: " Mon, 20 Feb 2017".to_date
                                                }
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Memorial Day') }
      it_should_behave_like "a federal holiday", { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: "Mon, 29 May 2017".to_date
                                                }
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Labor Day') }
      it_should_behave_like "a federal holiday", { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: "Mon, 04 Sep 2017".to_date
                                                }
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Columbus Day') }
      it_should_behave_like "a federal holiday", { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: "Mon, 09 Oct 2017".to_date
                                                }
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Thanksgiving Day') }
      it_should_behave_like "a federal holiday", { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: "Thu, 23 Nov 2017".to_date
                                                }
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Veterans Day') }
      it_should_behave_like "a federal holiday", { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: "Fri, 10 Nov 2017".to_date
                                                }
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'New Year Day') }
      it_should_behave_like "a federal holiday", { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: "Mon, 02 Jan 2017".to_date
                                                }
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Christmas Day') }
      it_should_behave_like "a federal holiday", { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: "Mon, 25 Dec 2017".to_date
                                                }
    end

    private

    def invoke_task
      Rake::Task["load_federal_holidays:update_federal_holidays"].invoke
    end
  end
end
