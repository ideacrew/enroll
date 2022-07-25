# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module XmlTransforms
      # Person params to be transformed.
    class EmbeddedXmlBuilder

      include Dry::Monads[:result, :do]

      def call(*args)
        args = args.first
        valid_params = yield validate(args)
        valid_enrollment = yield find(valid_params)
        payload = yield generate_json(valid_enrollment)
        entity = yield initialize_entity(payload)
        seralized_xml = yield to_serialized_obj(entity)
        _validate_xml = yield validate_xml(seralized_xml)

        Success(xml)
      end

      private

      def validate(params)
        return Failure("No enrollment hbx_id") unless params[:enrollment_hbx_id].present?
        return Failure("embed_xml feature is turned off") unless EnrollRegistry[:carefirst_pay_now].setting(:embed_xml).item

        Success(params)
      end

      def find(params)
        result = Operations::HbxEnrollments::Find.new.call({hbx_id: params[:enrollment_hbx_id] })
        result.success? ?  Success(result) : Failure("Enrollment is not present for the given hbx_id: #{params[:enrollment_hbx_id]}")
      end

      def generate_json(enrollment)
        # TODO build json based on enrollment
        {}
      end

      def initialize_entity(payload)
        result = Try do
          AcaEntities::Saml::EmbeddedXml.new(payload)
        end.to_result

        if result.success?
          result
        else
          Failure("entity-AccountTransferRequest -> #{result.failure}")
        end
      end

      def to_serialized_obj(entity)
        seralized_xml = Try do
          AcaEntities::Serializers::Xml::Saml::EmbeddedXml.domain_to_mapper(entity)
        end.to_result

        if seralized_xml.success?
          seralized_xml
        else
          Failure("Serializers-AccountTransferRequest -> #{seralized_xml.failure}")
        end
      end

      def validate_xml(seralized_xml)
        document = Nokogiri::XML(seralized_xml.to_xml)
        xsd_path = File.open(Pathname.pwd.join("lib/aca_entities/saml/schema/pay_now_embedded.xsd"))
        schema_location = File.expand_path(xsd_path)
        schema = Nokogiri::XML::Schema(File.open(schema_location))
        result = schema.validate(document).each_with_object([]) do |error, collect|
          collect << error.message
        end

        if result.empty?
          Success(true)
        else
          Failure("validate_xml -> #{result}")
        end
      end
    end
  end
end
