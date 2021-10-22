# frozen_string_literal: true

AcaEntities::Configuration::Encryption.configure do |config|
  config.secret_key = ENV['RBNACL_SECRET_KEY'] || "C639A572E14D5075C526FDDD43E4ECF6B095EA17783D32EF3D2710AF9F359DD4"
  config.iv = ENV['RBNACL_IV'] || "1234567890ABCDEFGHIJKLMN"
end