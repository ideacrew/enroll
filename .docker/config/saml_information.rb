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
    'pay_now_issuer',
    'kaiser_pay_now_url',
    'kaiser_pay_now_relay_state',
    'pay_now_private_key_location',
    'pay_now_x509_cert_location',
    'kaiser_pay_now_audience',
    'delta_dental_pay_now_url',
    'delta_dental_pay_now_audience',
    'delta_dental_pay_now_relay_state',
    'dentegra_pay_now_url',
    'dentegra_pay_now_audience',
    'dentegra_pay_now_relay_state',
    'dominion_national_pay_now_url',
    'dominion_national_pay_now_audience',
    'dominion_national_pay_now_relay_state',
    'best_life_pay_now_url',
    'best_life_pay_now_audience',
    'best_life_pay_now_relay_state',
    'metlife_pay_now_url',
    'metlife_pay_now_audience',
    'metlife_pay_now_relay_state',
    'carefirst_pay_now_url',
    'carefirst_pay_now_audience',
    'carefirst_pay_now_relay_state',
    'aetna_pay_now_url',
    'aetna_pay_now_audience',
    'aetna_pay_now_relay_state',
    'unitedhealthcare_pay_now_url',
    'unitedhealthcare_pay_now_audience',
    'unitedhealthcare_pay_now_relay_state',
    'northeast_delta_dental_pay_now_url',
    'northeast_delta_dental_pay_now_audience',
    'northeast_delta_dental_pay_now_relay_state',
    'anthem_blue_cross_and_blue_shield_pay_now_url',
    'anthem_blue_cross_and_blue_shield_pay_now_audience',
    'anthem_blue_cross_and_blue_shield_pay_now_relay_state',
    'harvard_pilgrim_health_care_pay_now_url',
    'harvard_pilgrim_health_care_pay_now_audience',
    'harvard_pilgrim_health_care_pay_now_relay_state',
    'community_health_options_pay_now_url',
    'community_health_options_pay_now_audience',
    'community_health_options_pay_now_relay_state'
  ]

  attr_reader :config

  # TODO: I have a feeling we may be using this pattern
  #       A LOT.  Look into extracting it if we repeat.
  def initialize
    @config = YAML.safe_load(ERB.new(File.read(File.join(Rails.root,'config', 'saml.yml'))).result)
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
