# frozen_string_literal: true

module Operations
  module HbxAdmin
    # This Operation is responsible for advancing the date of record to a future date.
    class TimeJump
      include Dry::Monads[:do, :result]

      def call(params)
        new_date = yield validate(params)
        result = yield travel_to(new_date)

        Success(result)
      end

      private

      def validate(params)
        new_date = Date.parse(params[:new_date])

        if new_date > Date.today && new_date > TimeKeeper.date_of_record
          Success(new_date)
        else
          Failure('Invalid date, please select a future date')
        end
      rescue ArgumentError
        Failure('Unable to parse date, please enter a valid date')
      end

      def travel_to(new_date)
        TimeKeeper.instance.set_date_of_record(new_date)

        if TimeKeeper.date_of_record.strftime('%m/%d/%Y') == new_date.to_s
          Success("Time Hop is successful, Date is advanced to #{TimeKeeper.date_of_record.strftime('%m/%d/%Y')}")
        else
          Failure('Time Hop failed, please try again')
        end
      end
    end
  end
end