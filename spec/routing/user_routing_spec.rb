require 'rails_helper'

describe UsersController do

  describe 'routing' do

    it 'route to User#lockable' do
      expect(get('/users/1/lockable')).to route_to('users#lockable', id: '1')
    end
  end

end