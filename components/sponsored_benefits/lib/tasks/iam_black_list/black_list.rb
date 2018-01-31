BlackList = Struct.new(
  :first_name, :last_name, :login, :email, :type
) do

  def self.from_row(row)
    list_item = BlackList.new
    list_item.first_name = row[0].present? ? row[0].strip : ""
    list_item.last_name = row[1].present? ? row[1].strip : ""
    list_item.login = row[2].present? ? row[2].strip : ""
    list_item.email = row[3].present? ? row[3].strip : ""
    list_item.type = row[4].present? ? row[4].strip : ""
    list_item
  end

  def find_curam_user
    CuramUser.match_username(login).first
  end

  def update_or_create_curam_user
    cu = find_curam_user
    case
    when cu && email.nil?
      #do nothing
    when cu && cu.email.nil? && email
      #update cu.email
      cu.email = email
      unless cu.save
        puts "unable to update curam user #{cu.email} iam: #{email}"
      end
    when cu && cu.email && email
      #copy cu with email
      new_cu = cu.dup
      new_cu.email = email
      unless new_cu.save
        puts "unable to create curam user #{cu.username} iam: #{email} "
      end
    when cu.nil?
      #new cu with item data
      new_cu = CuramUser.new(
        email: email, first_name: first_name, last_name: last_name, username: login
        )
      unless new_cu.save
        puts "unable to create curam user #{new_cu.username} iam: #{email} "
      end
    else
      puts "It should not have been possible to get here. curam user #{cu.to_s} :: iam: #{self.to_s}"
    end
  end
end
