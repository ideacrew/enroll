require 'rails_helper'

RSpec.describe User, :type => :model do

  let(:valid_params) do
    {
      email: "test@test.com",
      password: "test1234",
      password_confirmation: "test1234",
      approved: true,
      person: {first_name: "john", last_name: "doe", ssn: "123456789"}
    }
  end

  describe 'user' do

    context 'when email' do
      let(:params){valid_params.deep_merge!({email: "test"})}
      it 'is invalid' do
        expect(User.create(**params).errors[:email].any?).to be_truthy
        expect(User.create(**params).errors[:email]).to eq ["is invalid"]
      end
    end

    context 'when email' do
      let(:params){valid_params.deep_merge!({email: ""})}
      it 'is empty' do
        expect(User.create(**params).errors[:email].any?).to be_truthy
        expect(User.create(**params).errors[:email]).to eq ["can't be blank"]
      end
    end

    context 'when password' do
      let(:params){valid_params.deep_merge!({password: ""})}
      it 'is empty' do
        expect(User.create(**params).errors[:password].any?).to be_truthy
        expect(User.create(**params).errors[:password]).to eq ["can't be blank"]
        expect(User.create(**params).errors[:password_confirmation]).to eq ["doesn't match Password"]
      end
    end

    context 'when password & password confirmation' do
      let(:params){valid_params.deep_merge!({password: "123"})}
      it 'does not match' do
        expect(User.create(**params).errors[:password].any?).to be_truthy
        expect(User.create(**params).errors[:password_confirmation].any?).to be_truthy
        expect(User.create(**params).errors[:password]).to eq ["is too short (minimum is 8 characters)"]
        expect(User.create(**params).errors[:password_confirmation]).to eq ["doesn't match Password"]
      end
    end

    context 'when associated person' do
      let(:params){valid_params}
      it 'first name is invalid' do
        params[:person][:first_name] = ""
        expect(User.create(**params).errors[:person].any?).to be_truthy
        expect(User.create(**params).errors[:person]).to eq ["is invalid"]
        expect(User.create(**params).person.errors[:first_name].any?).to be_truthy
        expect(User.create(**params).person.errors[:first_name]).to eq ["can't be blank"]
      end

      it 'last name is invalid' do
        params[:person][:last_name] = ""
        expect(User.create(**params).errors[:person].any?).to be_truthy
        expect(User.create(**params).errors[:person]).to eq ["is invalid"]
        expect(User.create(**params).person.errors[:last_name].any?).to be_truthy
        expect(User.create(**params).person.errors[:last_name]).to eq ["can't be blank"]
      end

      it 'ssn is invalid' do
        params[:person][:ssn] = "123"
        expect(User.create(**params).errors[:person].any?).to be_truthy
        expect(User.create(**params).errors[:person]).to eq ["is invalid"]
        expect(User.create(**params).person.errors[:ssn].any?).to be_truthy
        expect(User.create(**params).person.errors[:ssn]).to eq ["SSN must be 9 digits"]
      end
    end

    context "when all params are valid" do
      let(:params){valid_params}
      it "should not have errors on create" do
        record = User.create(**params)
        expect(record).to be_truthy
        expect(record.errors.messages.size).to eq 0
      end
    end

  end
end
