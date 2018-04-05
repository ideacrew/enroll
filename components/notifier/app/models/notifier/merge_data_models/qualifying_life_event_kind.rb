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
        title: Settings.aca.qle.title,
        event_on: TimeKeeper.date_of_record - Settings.aca.qle.eligible_event_on.days,
        start_on: TimeKeeper.date_of_record - Settings.aca.qle.start_on.days,
        end_on: TimeKeeper.date_of_record - Settings.aca.qle.end_on.days,
        reported_on: TimeKeeper.date_of_record - Settings.aca.qle.reported_on.days
        })
    end
  end
end
