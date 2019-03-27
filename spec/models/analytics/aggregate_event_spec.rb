require 'rails_helper'

describe Analytics::AggregateEvent, type: :model, dbclean: :after_each do
# describe Analytics::AggregateEvent, type: :model do
  let(:event_topic)   { "auto_renewal" }
  let(:time_stamp)    { DateTime.new(2015,11,11,11,11,0,'-4') }

  context "An event is sent to increment_time method without required topic keyword" do
    it "should raise an error" do
      expect{Analytics::AggregateEvent.increment_time}.to raise_error ArgumentError
    end
  end

  context "No events exist" do
    it "Daily time dimension document should not exist for the time stamp period" do
      expect(Analytics::Dimensions::Daily.all.size).to eq 0
    end

    it "Weekly time dimension document should not exist for the time stamp period" do
      expect(Analytics::Dimensions::Weekly.all.size).to eq 0
    end

    it "Monthly time dimension document should not exist for the time stamp period" do
      expect(Analytics::Dimensions::Monthly.all.size).to eq 0
    end

    context "and an event is sent to increment_time method with a time stamp value" do
      let(:result) { Analytics::AggregateEvent.increment_time(topic: event_topic, moment: time_stamp) }
      let(:hour_field)      { "h" + time_stamp.hour.to_s }
      let(:minute_field)    { "m" + time_stamp.minute.to_s }
      let(:week_day_field)  { "d" + week_day.to_s }
      let(:month_day_field) { "d" + month_day.to_s }
      let(:week_day)        { time_stamp.wday }
      let(:calendar_month)  { time_stamp.month }
      let(:calendar_year)   { time_stamp.year }
      let(:calendar_week)   { time_stamp.cweek }
      let(:month_day)       { time_stamp.month }

      context "the method should return an array with object for each time dimension" do
        it "should return an array containing a daily doc" do
          expect(result).to include(a_kind_of(Analytics::Dimensions::Daily))
        end

        it "should return an array containing a weekly doc" do
          expect(result).to include(a_kind_of(Analytics::Dimensions::Weekly))
        end

        it "should return an array containing a monthly doc" do
          expect(result).to include(a_kind_of(Analytics::Dimensions::Monthly))
        end
      end

      context "each time dimension should be updated" do
        let(:daily_dimension)   { Analytics::Dimensions::Daily.where(topic: event_topic, date: time_stamp).first }
        let(:weekly_dimension)  { Analytics::Dimensions::Weekly.where(topic: event_topic, date: time_stamp).first }
        let(:monthly_dimension) { Analytics::Dimensions::Monthly.where(topic: event_topic, date: time_stamp).first }

        before do
          Analytics::AggregateEvent.increment_time(topic: event_topic, moment: time_stamp)
        end

        # Daily values
        it "should increment the daily event count by one at the proper time instant" do
          expect(daily_dimension.hours_of_day.eval(hour_field)).to eq 1
          expect(daily_dimension.minutes_of_hours.where(hour: time_stamp.hour).first.read_attribute(minute_field)).to eq 1
        end

        it "should set daily week_day attribute to correct value" do
          expect(daily_dimension.week_day).to eq week_day
        end

        # Weekly values
        it "should increment the weekly event count by one at the proper time instant" do
          expect(weekly_dimension.read_attribute(week_day_field)).to eq 1
        end

        it "should set weekly calendar week attribute to correct value" do
          expect(weekly_dimension.week).to eq calendar_week
        end

        it "should set weekly year attribute to correct value" do
          expect(weekly_dimension.year).to eq calendar_year
        end

        # Monthly values
        it "should increment the monthly event count by one at the proper time instant" do
          expect(monthly_dimension.read_attribute(month_day_field)).to eq 1
        end

        it "should set month day attribute to correct value" do
          expect(monthly_dimension.month).to eq calendar_month
        end

        it "should set weekly year attribute to correct value" do
          expect(monthly_dimension.year).to eq calendar_year
        end
      end
    end
  end

  context "A series of events are recorded over a period of time" do
    let(:event_topic)   { "individual_initial_enrollments" }
    let(:event_count)   { 135 }
    let(:min_start_at)  { Time.new(2015, 11, 1, 0, 0, 0).to_i }
    let(:max_end_at)    { Time.new(2016, 1, 31, 23, 59, 59).to_i }

    before do
      (1..event_count).each { |i| Analytics::AggregateEvent.increment_time( 
                                                                              topic: event_topic,
                                                                              moment: Time.at(rand(min_start_at..max_end_at))
                                                                            ) 
                                                                          }
    end

    it "should find all events" do
      expect(Analytics::AggregateEvent.topic_count_monthly(topic: event_topic)).to eq []
    end
  end

end
