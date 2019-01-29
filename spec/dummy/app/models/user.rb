class User

  include Mongoid::Document
  include Mongoid::Timestamps

  def self.generate_valid_password
  end
end
