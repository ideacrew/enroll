avengers = {
  black_panther: {
    username: 'black_panther',
    password: '$3cr3tP@55w0rd',
    email: 'black_panther@avengers.org',
    first_name: "T'Challa",
    last_name: 'Wakandason'
  },
  iron_man: {
    username: 'iron_man',
    password: '$3cr3tP@55w0rd',
    email: 'iron_man@avengers.org',
    first_name: 'Tony',
    last_name: 'Stark'
  },
  captain_america: {
    username: 'captain_america',
    password: '$3cr3tP@55w0rd',
    email: 'captain_america@avengers.org',
    first_name: 'Steve',
    last_name: 'Rodgers'
  },
  black_widow: {
    username: 'black_widow',
    password: '$3cr3tP@55w0rd',
    email: 'black_widow@avengers.org',
    first_name: 'Natasha',
    last_name: 'Romanoff'
  },
  thor: {
    username: 'thor',
    password: '$3cr3tP@55w0rd',
    email: 'thor@avengers.org',
    first_name: 'Thor',
    last_name: 'Odinson'
  },
  doctor_strange: {
    username: 'doctor_strange',
    password: '$3cr3tP@55w0rd',
    email: 'doctor_strange@avengers.org',
    first_name: 'Steven',
    last_name: 'Strange'
  }
}

avengers.each { |k, v| Operations::Accounts::Delete.new.call(login: v[:username]) }
avengers.each do |k, v|
  result = Operations::Users::Create.new.call(v)

  if result.success?
    user_attributes = result.success[:user]
    user = User.find(user_attributes[:_id])
    user.update(v.slice(:email))
    user.build_person(v.slice(:first_name, :last_name)).save
  end
end
  


