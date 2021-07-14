class SamlInformation

  class MissingKeyError < StandardError
    def initialize(key)
      super("Missing required key: #{key}")
    end
  end

  include Singleton

  REQUIRED_KEYS = [
    'assertion_consumer_service_url',
    'assertion_consumer_logout_service_url',
    'issuer',
    'idp_entity_id',
    'idp_sso_target_url',
    'idp_slo_target_url',
    'idp_cert',
    'name_identifier_format',
    'idp_cert_fingerprint',
    'idp_cert_fingerprint_algorithm',
    'curam_landing_page_url',
    'saml_logout_url',
    'account_conflict_url',
    'account_recovery_url',
    'iam_login_url',
    'curam_broker_dashboard',
    'kaiser_pay_now_issuer',
    'kaiser_pay_now_url',
    'kaiser_pay_now_relay_state',
    'kaiser_pay_now_private_key_location',
    'kaiser_pay_now_x509_cert_location',
    'kaiser_pay_now_audience',
    'delta_dental_pay_now_issuer',
    'delta_dental_pay_now_url',
    'delta_dental_pay_now_private_key_location',
    'delta_dental_pay_now_x509_cert_location',
    'delta_dental_pay_now_audience',
    'delta_dental_pay_now_relay_state',
    'dentegra_pay_now_issuer',
    'dentegra_pay_now_url',
    'dentegra_pay_now_private_key_location',
    'dentegra_pay_now_x509_cert_location',
    'dentegra_pay_now_audience',
    'dentegra_pay_now_relay_state',
    'dominion_national_pay_now_issuer',
    'dominion_national_pay_now_url',
    'dominion_national_pay_now_private_key_location',
    'dominion_national_pay_now_x509_cert_location',
    'dominion_national_pay_now_audience',
    'dominion_national_pay_now_relay_state',
    'best_life_pay_now_issuer',
    'best_life_pay_now_url',
    'best_life_pay_now_private_key_location',
    'best_life_pay_now_x509_cert_location',
    'best_life_pay_now_audience',
    'best_life_pay_now_relay_state',
    'metlife_pay_now_issuer',
    'metlife_pay_now_url',
    'metlife_pay_now_private_key_location',
    'metlife_pay_now_x509_cert_location',
    'metlife_pay_now_audience',
    'metlife_pay_now_relay_state',
    'carefirst_pay_now_issuer',
    'carefirst_pay_now_url',
    'carefirst_pay_now_private_key_location',
    'carefirst_pay_now_x509_cert_location',
    'carefirst_pay_now_audience',
    'carefirst_pay_now_relay_state',
    'aetna_pay_now_issuer',
    'aetna_pay_now_url',
    'aetna_pay_now_private_key_location',
    'aetna_pay_now_x509_cert_location',
    'aetna_pay_now_audience',
    'aetna_pay_now_relay_state',
    'unitedhealthcare_pay_now_issuer',
    'unitedhealthcare_pay_now_url',
    'unitedhealthcare_pay_now_private_key_location',
    'unitedhealthcare_pay_now_x509_cert_location',
    'unitedhealthcare_pay_now_audience',
    'unitedhealthcare_pay_now_relay_state'
  ]

  attr_reader :config

  # TODO: I have a feeling we may be using this pattern
  #       A LOT.  Look into extracting it if we repeat.
  def initialize
    @config = YAML.load_file(File.join(Rails.root,'config', 'saml.yml'))
    ensure_configuration_values(@config)
  end

  def ensure_configuration_values(conf)
    REQUIRED_KEYS.each do |k|
      if @config[k].blank?
        raise MissingKeyError.new(k)
      end
    end
  end

  def self.define_key(key)
    define_method(key.to_sym) do
      config[key.to_s]
    end
    self.instance_eval(<<-RUBYCODE)
      def self.#{key.to_s}
        self.instance.#{key.to_s}
      end
    RUBYCODE
  end

  REQUIRED_KEYS.each do |k|
    define_key k
  end

end
