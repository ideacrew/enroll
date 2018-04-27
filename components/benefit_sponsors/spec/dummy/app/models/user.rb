class User
  include Mongoid::Document
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :timeoutable, :authentication_keys => {email: false, login: true}
end
