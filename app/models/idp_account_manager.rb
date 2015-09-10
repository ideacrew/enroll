require 'securerandom'

class IdpAccountManager
  attr_accessor :provider
  include Singleton

  def initialize
    @provider = AmqpSource
  end

  def check_existing_account(personish)
    person_details = {
      :first_name => personish.first_name,
      :last_name => personish.last_name,
      :dob => personish.dob.strftime("%Y%m%d")
    }
    if !personish.ssn.blank?
      person_details[:ssn] = personish.ssn 
    end
    provider.check_existing_account(
      person_details
    )
  end

  def create_account(email, password)
    provider.create_account({
      :email => email,
      :password => password
    })
  end

  def self.set_provider(prov)
    self.instance.provider = prov
  end

  def self.slug!
    self.set_provider(SlugSource)
  end

  def self.check_existing_account(personish)
    self.instance.check_existing_account(personish)
  end

  def self.create_account(email, password)
    self.instance.create_account(email, password)
  end

  class AmqpSource
    def self.check_existing_account(args)
      invoke_service("account_management.check_existing_account", args) do |code|
        case code
        when "404"
          :not_found
        when "409"
          :too_many_matches
        when "302"
          :existing_account
        else
          :service_unavailable
        end
      end
    end

    def self.create_account(args)
      invoke_service("account_management.create_account", args) do |code|
        case code
        when "201"
          :created
        else
          :service_unavailable
        end
      end
    end

    def self.invoke_service(key, args, &blk)
      begin
        request_result = Acapi::Requestor.request(key, args)
        result_code = request_result.stringify_keys["return_status"].to_s
        case result_code
        when "503"
          :service_unavailable
        else
          blk.call(result_code)
        end
      rescue Timeout::Error => e
        :service_unavailable
      end
    end
  end

  class SlugSource
    def self.create_account(args)
      :created
    end

    def self.check_existing_account(args)
      :not_found
    end
  end
end

# Fix slug setting on request reload
unless Rails.env.production?
  IdpAccountManager.slug!
end

