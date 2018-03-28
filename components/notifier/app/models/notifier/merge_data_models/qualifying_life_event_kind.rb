module Notifier
  class MergeDataModels::QualifyingLifeEventKind
    include Virtus.model

    attribute :title, String
   	attribute :event_on, Date
   	attribute :start_on, Date
   	attribute :end_on, Date
   	attribute :reported_on, Date
    attribute :reporting_deadline, Date

    def self.stubbed_object
      Notifier::MergeDataModels::QualifyingLifeEventKind.new({
        title: 'Married',
        event_on: TimeKeeper.date_of_record.strftime('%m/%d/%Y') - 10.days,
        start_on: TimeKeeper.date_of_record.strftime('%m/%d/%Y') - 10.days,
        end_on: TimeKeeper.date_of_record.strftime('%m/%d/%Y') + 20.days,
        reported_on: TimeKeeper.date_of_record.strftime('%m/%d/%Y')
        })
    end
  end
end
