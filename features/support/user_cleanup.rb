After do
  if User.all.present?
    User.destroy_all
  end
end
