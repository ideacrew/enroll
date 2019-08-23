def load_dc_issuer_profile_seed
  glob_pattern = File.join(File.dirname(__FILE__), "fixtures", "issuer_profiles", "*.yaml")

  Dir.glob(glob_pattern).each do |f_name|
    loaded_class = ::BenefitSponsors::Organizations::ExemptOrganization
    loaded_class = ::BenefitSponsors::Organizations::IssuerProfile
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end