class CuramUser
  include Mongoid::Document

  field :first_name, type: String
  field :last_name, type: String
  field :ssn, type: String
  field :dob, type: Date

  index({ssn: 1, dob: 1})
  index({lname: 1, fname: 1, dob: 1})

  def self.match_ssn ssn
    CuramUser.where(ssn: ssn).exists?
  end

  def self.match_ssn_dob(ssn, dob)
    CuramUser.where(ssn: ssn, dob: dob)
  end

  def self.match_fname_lname_dob(fname, lname, dob)
    f_name_regex = Regexp.compile(Regexp.escape(fname.to_s), true)
    l_name_regex = Regexp.compile(Regexp.escape(lname.to_s), true)
    self.where(first_name: f_name_regex, last_name: l_name_regex, dob: dob)
  end

  def self.search_for(fname, lname, ssn, dob)
    if ssn.blank?
      self.match_fname_lname_dob(fname, lname, dob)
    else
      self.match_ssn_dob(ssn, dob)
    end
  end

end
