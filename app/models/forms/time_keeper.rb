module Forms
  class TimeKeeper
    include ActiveModel::Model
    include ActiveModel::Validations

    delegate :date_of_record, :save, :valid?, to: :'::TimeKeeper'

    attr_reader :forms_date_of_record

    def date_of_record=(val)
      @forms_date_of_record = val
    end

    def set_date_of_record(date)
      ::TimeKeeper.set_date_of_record(date)
    end

    def instance
      ::TimeKeeper.instance
    end
  end
end