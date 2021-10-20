# frozen_string_literal: true

RSpec.shared_context 'account' do
  let(:avengers) do
    %w[iron_man captain_america black_widow thor doctor_strange black_panther]
  end

  let(:black_panther) do
    {
      username: 'black_panther',
      password: '$3cr3tP@55w0rd',
      email: 'black_panther@avengers.org',
      first_name: "T'Challa",
      last_name: 'Wakandason'
    }
  end

  let(:iron_man) do
    {
      username: 'iron_man',
      password: '$3cr3tP@55w0rd',
      email: 'iron_man@avengers.org',
      first_name: 'Tony',
      last_name: 'Stark'
    }
  end

  let(:captain_america) do
    {
      username: 'captain_america',
      password: '$3cr3tP@55w0rd',
      email: 'captain_americak@avengers.org',
      first_name: 'Steve',
      last_name: 'Rodgers'
    }
  end

  let(:black_widow) do
    {
      username: 'black_window',
      password: '$3cr3tP@55w0rd',
      email: 'black_window@avengers.org',
      first_name: 'Natasha',
      last_name: 'Romanoff'
    }
  end

  let(:thor) do
    {
      username: 'thor',
      password: '$3cr3tP@55w0rd',
      email: 'thor@avengers.org',
      first_name: 'Thor',
      last_name: 'Odinson'
    }
  end

  let(:doctor_strange) do
    {
      username: 'doctor_strange',
      password: '$3cr3tP@55w0rd',
      email: 'doctor_strange@avengers.org',
      first_name: 'Steven',
      last_name: 'Strange'
    }
  end

  def create_avenger_accounts
    require pry
    binding.pry
    avengers.each do |username|
      Operations::Accounts::Create.new.call(username.value)
    end
  end

  def delete_avenger_accounts
    avengers.each { |username| Operations::Accounts::Delete.new.call(username) }
  end
end
