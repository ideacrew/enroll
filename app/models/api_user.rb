# app/models/api_user.rb
class ApiUser < User
  devise :jwt_authenticatable, jwt_revocation_strategy: Blacklist

  def generate_jwt
    JWT.encode({ id: id,
                exp: 5.days.from_now.to_i },
               Rails.env.devise.jwt.secret_key)
  end

  def jwt_subject
  end

  def on_jwt_dispatch(p, l)
  end

end
