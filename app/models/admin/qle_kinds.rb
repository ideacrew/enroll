module Admin
  module QleKinds
    class QleKindsContainer
      extend Dry::Container::Mixin

      register "create_params_validator" do
        ::QleKinds::CreateParamsValidator.new
      end

      register "create_domain_validator" do
        ::QleKinds::CreateDomainValidator.new
      end

      register "create_virtual_model" do
        Admin::QleKinds::CreateRequest
      end
    end

    Injection = Dry::AutoInject(QleKindsContainer)
  end
end