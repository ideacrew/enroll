# frozen_string_literal: true

module Operations
  module HbxAdmin
    # This Operation is responsible for advancing the date of record to a future date.
    class TimeJump
      include Dry::Monads[:do, :result]
      include L10nHelper

      def call(params)
        new_date = yield validate(params)
        result = yield travel_to(new_date)

        Success(result)
      end

      private

      def validate(params)
        new_date = Date.parse(params[:new_date])

        if new_date >= Date.today
          Success(new_date)
        else
          Failure(l10n("admin_actions.time_jump.invalid_date"))
        end
      rescue ArgumentError
        Failure(l10n("admin_actions.time_jump.invalid_date_format"))
      end

      def travel_to(new_date)
        TimeKeeper.instance.set_date_of_record(new_date)

        if TimeKeeper.date_of_record.strftime('%m/%d/%Y') == new_date.to_s
          Success("#{l10n('admin_actions.time_jump.success')} #{TimeKeeper.date_of_record.strftime('%m/%d/%Y')}")
        else
          Failure(l10n("admin_actions.time_jump.failure"))
        end
      end
    end
  end
end