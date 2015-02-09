module Requests
  class EmployeeRequest
    include ActiveModel::Model

    attr_accessor :name_first, :name_last, :name_middle
    attr_accessor :gender, :ssn, :dob

    validates_presence_of :name_first, :allow_blank => false
    validates_presence_of :name_last, :allow_blank => false
  end
end
