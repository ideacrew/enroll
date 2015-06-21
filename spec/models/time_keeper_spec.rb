require 'rails_helper'

RSpec.describe TimeKeeper, type: :model do

  context "the system initializes" do
    context "and a date_of_record value isn't available in the locally-persisted store" do
      it "should send a syslog info message to the enterprise logger"

      context "and the date_of_record isn't available from enterprise service" do
        it "should send a syslog critical error to the enterprise logger"
        it "should halt the system initialization process to avoid corrupting records"

      end
    end
  end

  context "a message is received with a new date_of_record" do
    context "and new date the same as the current date_of_record" do
      it "should ignore the message"
    end

    context "and new date is prior to the current date_of_record" do
      it "should ignore the message"
      it "should send a syslog critical error to the enterprise logger"
    end

    context "and new date is one day later than current date_of_record" do
      it "should send the new date_of_record to registered models"
      it "should persist the new date_of_record in the local data store"
      it "should send a syslog info message to the enterprise logger"
    end

    context "and new date is more than one day later than curent date_of_record" do
      it "should send the new date_of_record to registered models for each day" 
      it "should persist in the local data storet the new date_of_record for each successful advance"
      it "should send a syslog info message to the enterprise logger for each successful advance"
    end
  end

end
