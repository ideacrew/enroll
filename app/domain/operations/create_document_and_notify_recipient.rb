# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  # Consumes payload from Polypress, creates document object for recipient, sends secure message and generic alert
  class CreateDocumentAndNotifyRecipient
    send(:include, Config::SiteConcern)
    send(:include, Dry::Monads[:result, :do, :try])

    def call(params)
      validate_params = yield validate_params(params)
      resource = yield fetch_resource(validate_params)
      document = yield create_document(resource, params)
      _secure_message = yield send_secure_message(resource, document)
      result = yield send_generic_notice_alert(resource)
      Success(result)
    end

    private

    def validate_params(params)
      return Failure({ :message => ['Resource id is missing'] }) if params[:subjects][0][:id].nil?
      return Failure({ :message => ['Document Identifier is missing'] }) if params[:id].nil?

      Success(params.deep_symbolize_keys)
    end

    def fetch_resource(validate_params)
      hbx_assigned_id = validate_params[:subjects][0][:id]
      family = Family.where(hbx_assigned_id: hbx_assigned_id).first
      person = family&.primary_person

      if person
        Success(person)
      else
        Failure({ :message => ["No primary person found for the given family_hbx_id: #{hbx_assigned_id}"] })
      end
    end

    def create_document(resource, params)
      ::Operations::Documents::Create.new.call(resource: resource, document_params: params, doc_identifier: params[:id])
    end

    # rubocop:disable Layout/LineLength
    # rubocop:disable Style/StringConcatenation
    def send_secure_message(resource, document)
      document_title = document.title.gsub(/[^0-9a-z.]/i,'').gsub('.pdf', '')
      body = "<br>You can download the notice by clicking this link " \
             "<a href=" \
             "#{Rails.application.routes.url_helpers.cartafact_document_download_path(resource.class.to_s, resource.id.to_s, 'documents', document.id)}?content_type=#{document.format}&filename=#{document.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" \
             " target='_blank'>" + document_title + "</a>"
      resource.inbox.messages << Message.new(body: body, subject: document_title, from: site_short_name)
      resource.save
      Success(resource)
    end
    # rubocop:enable Layout/LineLength
    # rubocop:enable Style/StringConcatenation

    def send_generic_notice_alert(resource)
      ::Operations::SendGenericNoticeAlert.new.call(resource: resource)
    end

  end
end