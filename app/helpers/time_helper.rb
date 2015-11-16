module TimeHelper
  def time_remaining_in_words(user_created)
    last_day = user_created.to_date + 95.days
    days = (last_day.to_date - Time.now.to_date).to_i
    pluralize(days, 'day')
  end
end
