# frozen_string_literal: true

require 'rails_helper'

describe UsersController do

  describe 'routing' do
    it 'routes to #reset_password' do
      expect(get('/users/2/reset_password')).to route_to('users#reset_password', id: '2')
    end

    it 'routes to #confirm_reset_password' do
      expect(put('/users/2/confirm_reset_password')).to route_to('users#confirm_reset_password', id: '2')
    end
  end
end
