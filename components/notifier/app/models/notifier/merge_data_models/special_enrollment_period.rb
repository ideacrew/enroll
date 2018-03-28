module Notifier
   class MergeDataModels::SpecialEnrollmentPeriod
     include Virtus.model

        attribute :title, String
        attribute :event_on, Date
        attribute :start_on, Date
        attribute :end_on, Date
        attribute :reported_on, Date
 
     def self.stubbed_object
       Notifier::MergeDataModels::SpecialEnrollmentPeriod.new({
         title: 'Married',
         qle_on: TimeKeeper.date_of_record.strftime('%m/%d/%Y') - 10.days,
         start_on: TimeKeeper.date_of_record.strftime('%m/%d/%Y') - 10.days,
         end_on: TimeKeeper.date_of_record.strftime('%m/%d/%Y') + 20.days,
         submitted_at: TimeKeeper.datetime_of_record
         })
     end
   end
end