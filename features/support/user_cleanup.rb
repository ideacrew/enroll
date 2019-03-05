After do
  if User.present?
    User.last.destroy
  end
end
