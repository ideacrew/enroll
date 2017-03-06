module IvlCovered
  class EnrollmentType
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :month_one, type: String
    field :month_two, type: String
    field :month_three, type: String
    field :month_four, type: String

    field :month_five, type: String
    field :month_six, type: String
    field :month_seven, type: String
    field :month_eight, type: String

    field :month_nine, type: String
    field :month_ten, type: String
    field :month_eleven, type: String
    field :month_twelve, type: String
    
    field :auto_renew_one, type: String
    field :auto_renew_two, type: String
    field :auto_renew_three, type: String
    field :auto_renew_four, type: String

    field :auto_renew_five, type: String
    field :auto_renew_six, type: String
    field :auto_renew_seven, type: String
    field :auto_renew_eight, type: String

    field :auto_renew_nine, type: String
    field :auto_renew_ten, type: String
    field :auto_renew_eleven, type: String
    field :auto_renew_twelve, type: String

    field :auto_renew_total, type: String
    field :auto_renew_share, type: String

    field :active_renew_one, type: String
    field :active_renew_two, type: String
    field :active_renew_three, type: String
    field :active_renew_four, type: String

    field :active_renew_five, type: String
    field :active_renew_six, type: String
    field :active_renew_seven, type: String
    field :active_renew_eight, type: String

    field :active_renew_nine, type: String
    field :active_renew_ten, type: String
    field :active_renew_eleven, type: String
    field :active_renew_twelve, type: String

    field :active_renew_total, type: String
    field :active_renew_share, type: String

    field :newCustomer_one, type: String
    field :newCustomer_two, type: String
    field :newCustomer_three, type: String
    field :newCustomer_four, type: String

    field :newCustomer_five, type: String
    field :newCustomer_six, type: String
    field :newCustomer_seven, type: String
    field :newCustomer_eight, type: String

    field :newCustomer_nine, type: String
    field :newCustomer_ten, type: String
    field :newCustomer_eleven, type: String
    field :newCustomer_twelve, type: String

    field :newCustomer_total, type: String
    field :newCustomer_share, type: String

    field :sep_one, type: String
    field :sep_two, type: String
    field :sep_three, type: String
    field :sep_four, type: String

    field :sep_five, type: String
    field :sep_six, type: String
    field :sep_seven, type: String
    field :sep_eight, type: String

    field :sep_nine, type: String
    field :sep_ten, type: String
    field :sep_eleven, type: String
    field :sep_twelve, type: String

    field :sep_total, type: String
    field :sep_share, type: String

    field :total_one, type: String
    field :total_two, type: String
    field :total_three, type: String
    field :total_four, type: String

    field :total_five, type: String
    field :total_six, type: String
    field :total_seven, type: String
    field :total_eight, type: String

    field :total_nine, type: String
    field :total_ten, type: String
    field :total_eleven, type: String
    field :total_twelve, type: String

    field :total_total, type: String
    field :total_share, type: String

    default_scope ->{where(tile: "right_enrollment_type" )}

    # def self.enrollment_dashboard_stats
    #     enrollments =[ ]
    #     IvlCovered::EnrollmentType.all.each do |c|
    #         enrollments << c if c.month_one.present? && enrollments.size < 5 
    #     end
    #     enrollments
    # end
  end
end