# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  # Consumes payload from Polypress, creates document object for recipient, sends secure message and generic alert
  class CreateDocumentAndNotifyRecipient
    include Config::SiteConcern
    include Dry::Monads[:do, :result]

    def call(params)
      validate_params = yield validate_params(params)
      resource = yield fetch_resource(validate_params)
      document = yield create_document(resource, params)
      _secure_message = yield send_secure_message(resource, document, params[:file_name])
      result = yield send_notice(resource, params[:file_name])
      Success(result)
    end

    private

    def validate_params(params)
      return Failure({ :message => ['Resource id is missing'] }) if params[:subjects][0][:id].nil?
      return Failure({ :message => ['Document Identifier is missing'] }) if params[:id].nil?
      return Failure({:message => ['Document file name is missing']}) if params[:file_name].nil?

      Success(params.deep_symbolize_keys)
    end

    def fetch_resource(validate_params)
      person_hbx_id = validate_params[:subjects][0][:id]
      people = Person.by_hbx_id(person_hbx_id)

      if people.count == 1
        Success(people.first)
      else
        Failure({ :message => ["Found none or more than one people with given hbx_id: #{person_hbx_id}"] })
      end
    end

    def create_document(resource, params)
      ::Operations::Documents::Create.new.call(resource: resource, document_params: params, doc_identifier: params[:id])
    end

    # rubocop:disable Layout/LineLength
    # rubocop:disable Style/StringConcatenation
    def send_secure_message(resource, document, subject)
      document_title = document.title.gsub(/[^0-9a-z.]/i,'').gsub('.pdf', '')
      body = "<br>You can download the notice by clicking this link " \
             "<a href=" \
             "#{Rails.application.routes.url_helpers.cartafact_document_download_path(resource.class.to_s, resource.id.to_s, 'documents', document.id)}?content_type=#{document.format}&filename=#{document.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" \
             " target='_blank'>" + document_title + "</a>"
      resource.inbox.messages << Message.new(body: body, subject: subject, from: site_short_name)
      resource.save
      Success(resource)
    end
    # rubocop:enable Layout/LineLength
    # rubocop:enable Style/StringConcatenation

    def send_notice(resource, file_name)
      formatted_file_name = file_name.gsub(/[^0-9a-z.]/i,'').gsub('.pdf', '').downcase
      if EnrollRegistry.feature_enabled?(:ivl_tax_form_notice) && ['your1095ahealthcoveragetaxform', 'void1095ataxform', 'corrected1095ataxform'].include?(formatted_file_name)
        ::Operations::SendTaxFormNoticeAlert.new.call(resource: resource)
      else
        ::Operations::SendGenericNoticeAlert.new.call(resource: resource)
      end
    end
  end
end
