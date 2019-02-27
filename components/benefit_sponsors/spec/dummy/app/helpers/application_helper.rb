module ApplicationHelper
  def format_date(date_value)
    date_value.strftime("%m/%d/%Y") if date_value.respond_to?(:strftime)
  end
end
