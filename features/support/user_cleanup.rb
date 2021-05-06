After do
  User.destroy_all if User.all.present?
end
