require 'rails_helper'

describe Exchanges::QuestionsController do

  describe 'routing' do

    it 'route to Questions#index' do
      expect(get('/exchanges/questions')).to route_to('exchanges/questions#index')
    end

    it 'route to Questions#new' do
      expect(get('/exchanges/questions/new')).to route_to('exchanges/questions#new')
    end

    it 'route to Questions#create' do
      expect(post('/exchanges/questions')).to route_to('exchanges/questions#create')
    end

    it 'route to Questions#edit' do
      expect(get('/exchanges/questions/1/edit')).to route_to('exchanges/questions#edit', id: '1')
    end

    it 'route to Questions#update' do
      expect(put('/exchanges/questions/1')).to route_to('exchanges/questions#update', id: '1')
    end

    it 'route to Questions#destroy' do
      expect(delete('/exchanges/questions/1')).to route_to('exchanges/questions#destroy', id: '1')
    end
  end

end