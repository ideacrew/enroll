require 'rails_helper'

RSpec.describe Operations::Users::Create do
  subject { described_class.new }

  context 'Given valid parameters for a new user' do
    let(:username) { 'spiderman' }
    let(:password) { '$3cr3tP@55w0rd' }
    let(:email) { 'peter.parker@avengers.org' }
    let(:first_name) { 'Peter' }
    let(:last_name) { 'Parker' }
    let(:roles) { %w[consumer avenger] }

    # let(:client_roles) { %w[consumer avenger] }
    let(:client_id) { 'polypress' }

    let(:new_account) do
      {
        username: username,
        password: password,
        email: email,
        first_name: first_name,
        last_name: last_name,
        roles: roles
      }
    end

    context "and there's not an existing user account with same usernam" do
      it 'should create a new Keycloak Account and an associated User record' do
        result = subject.call(new_account)

        expect(result.success?).to be_truthy
        account_id = result.success[:account][:id]
        expect(result.success[:user][:account_id]).to_not eq account_id
      end
    end

    context 'and the user account does exist' do
      after { Operations::Accounts::Delete.new.call(login: username) }

      it 'should return a failure monad' do
        result = subject.call(new_account)

        expect(result.failure?).to be_truthy
        expect(result.failure[:new_user]).to be_falsey
      end
    end
  end
end

# access_token = Keycloak.generic_request(token['access_token'])
# access_token = "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJ0cm1QZ1BFNG1ZdVJMVXU2MGpySTZVTDk4c2R5anIzNGpQYmJ1UUZWdTFZIn0.eyJleHAiOjE2MzM2NDQ5MjUsImlhdCI6MTYzMzY0NDYyNSwianRpIjoiZmFmMWIwN2UtMGRjNy00ZmFhLWFmNTgtZGE0Mzg5NjRlZDBhIiwiaXNzIjoiaHR0cDovL2tleWNsb2FrOjgwODAvYXV0aC9yZWFsbXMvc2JlX2J1c2luZXNzX29wZXJhdGlvbnMiLCJhdWQiOlsicmVhbG0tbWFuYWdlbWVudCIsImFjY291bnQiXSwic3ViIjoiYmZmZWVjNWQtNDA0MC00ZGEwLTg0MDEtYmY2NWVhNzA2MWRmIiwidHlwIjoiQmVhcmVyIiwiYXpwIjoicG9seXByZXNzIiwiYWNyIjoiMSIsImFsbG93ZWQtb3JpZ2lucyI6WyJodHRwOi8va2V5Y2xvYWtfbG9jYWw6MzAwMCJdLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsiZGVmYXVsdC1yb2xlcy1zYmVfYnVzaW5lc3Nfb3BlcmF0aW9ucyIsIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJyZWFsbS1tYW5hZ2VtZW50Ijp7InJvbGVzIjpbInZpZXctcmVhbG0iLCJtYW5hZ2UtZXZlbnRzIiwidmlldy1ldmVudHMiLCJtYW5hZ2UtdXNlcnMiLCJ2aWV3LXVzZXJzIiwicXVlcnktY2xpZW50cyIsIm1hbmFnZS1jbGllbnRzIiwicXVlcnktZ3JvdXBzIiwicXVlcnktdXNlcnMiXX0sInBvbHlwcmVzcyI6eyJyb2xlcyI6WyJ1bWFfcHJvdGVjdGlvbiJdfSwiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJwcm9maWxlIGVtYWlsIiwiY2xpZW50SG9zdCI6IjE3Mi4yNi4wLjciLCJjbGllbnRJZCI6InBvbHlwcmVzcyIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwicHJlZmVycmVkX3VzZXJuYW1lIjoic2VydmljZS1hY2NvdW50LXBvbHlwcmVzcyIsImNsaWVudEFkZHJlc3MiOiIxNzIuMjYuMC43In0.plclB9EIn5_NgJz-wVhsoMhanAbzxD2Fv5PczW4asohxrGHyqI4Ni9V_qtwEt2oT1w3QuCaNSIpGtlGmNwkqczUVZtvPfuRGaf2LMdy1HVZJKtkpgKreiBXQRHS3viqxdnTHfMYYsJPB7vsqoIkg_4TrSEiGjQyB6WN64XJfb_u2NkUaDQ8zcOUeGM-Fts6Oeqlcovzyqt04MWKjzXwzk2k5QU4jx5IRge-8frMprkzyjYB7nOMWQ93n63biSOYhF6TBX5RS4iOaylV7hqWkl50PRlN4ISPy_ZH-qS4TZ0h8iFKjbx6aUdvYfPWZyXn4lJk9aId7sUma5TR2o842PA"
# header = { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => "Bearer #{access_token}" }
# final_url = ["http://keycloak:8080/auth", "admin", "realms", "sbe_business_operations", "users", "79336b48-fc95-47bb-956c-aa05e5932d67"].join('/')
# RestClient.get(final_url, header)
