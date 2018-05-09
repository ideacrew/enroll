module BenefitMarkets
  class Timescapes::BenefitPeriod
    include Mongoid::Document
    include Mongoid::Timestamps


    field :begin_on,  type: Date
    field :end_on,    type: Date

    validates_presence_of :begin_on, :end_on
    validate :ascending_dates


    scope :active_period_on,   ->(compare_date = TimeKeeper.date_of_record) { 
        where(:"begin_on".lte  => compare_date, :"end_on".gte => compare_date).first
      }


    def cover?(compare_date)
      return false unless begin_on.present? && end_on.present?
      begin_on..end_on.cover?(compare_date)
    end

    # Add next time-sequential benefit period to the datebase.  The next period begins one day following
    # the existing benefit period with the latest end date.  The period length default is one year.
    def self.create_following_period(period_length = 1.year)
      latest_period = BenefitMarkets::Time::BenefitPeriod.all.order_by(:'end_on'.desc).first
      BenefitMarkets::Time::BenefitPeriod.create(begin_on: latest_period.end_on + 1.day, end_on: latest_period.end_on + period_length)
    end

    private

    def ascending_dates
      # raise StandardError "begin date must start on or before end date" unless (self.begin_on <= self.end_on)
    end

  end
end
