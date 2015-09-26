class CuramUser
  include Mongoid::Document

  field :username, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :ssn, type: String
  field :dob, type: String

  validates :ssn, uniqueness: true, allow_blank: true

end
