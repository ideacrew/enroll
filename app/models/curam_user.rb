class CuramUser
  include Mongoid::Document

  field :username, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :ssn, type: String
  field :dob, type: String

  validates :ssn, uniqueness: true, allow_blank: true

  def self.match_ssn ssn
    CuramUser.where(ssn: ssn).exists?
  end

  def self.match_ssn_dob(ssn, dob)
    CuramUser.where(ssn: ssn, dob: dob).exists?
  end

end
