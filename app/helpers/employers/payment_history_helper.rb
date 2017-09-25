module Employers::PaymentHistoryHelper
  def paginate_upper_bound (num_payments)
    # 1 page only
    if (num_payments <= 10)
      return 1
     # multiple of 10 number of pages
    elsif (num_payments % 10 == 0)
      return num_payments / 10
    else
      # need to account for remainder
      return (num_payments / 10) + 1
    end
  end
end
