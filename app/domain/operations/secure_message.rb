# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  class SecureMessage
    send(:include, Dry::Monads[:result, :do])

    include Config::SiteConcern
    include Config::SiteHelper

    def call(params: )
      @resource = yield fetch_resource(params)
      if params[:file].present?
        doc_uri = yield upload_file_to_aws(params[:file])
        notice_document = yield create_notice_document_object(params, @resource, doc_uri)
      end
      notice_upload_email
      notice_upload_secure_message(@resource, params[:subject], params[:body], notice_document)
      Success(@resource)
    end

    private

    def fetch_person(person_id)
      person = ::Person.where(_id: person_id).first
      person ? Success(person) : Failure([:error, 'Person not found'])
    end

    def  upload_file_to_aws(file)
      doc_uri = Aws::S3Storage.save(get_file_path(file), 'notices')
      doc_uri ? Success(doc_uri) : Failure([:error, 'Could not save file'])
    end

    def create_notice_document_object(params, resource, uri)
      doc_params = {
        title: file_name(params),
        creator: "hbx_staff",
        subject: "notice",
        identifier: uri,
        format: "application/pdf"
      }
      notice = resource.documents.build(doc_params)
      notice.save
      Success(notice)
    end

    def notice_upload_email
      UserMailer.generic_notice_alert(recipient_name, "You have a new message from #{site_short_name}", recipient_to).deliver_now #TODO - electronic communication unless has_valid_resource? && !resource.can_receive_electronic_communication?
      Success(true)
    end

    def recipient_target
      if is_employer?
        @resource.staff_roles.first
      elsif is_person?
        @resource
      end
    end

    def has_valid_resource?
      (is_person? || is_employer?)
    end

    def recipient_name
      return nil unless recipient_target

      recipient_target.full_name.titleize
    end

    def recipient_to
      return nil unless recipient_target

      recipient_target.work_email_or_best
    end


    def is_employer?
      @resource.is_a?("BenefitSponsors::Organizations::AcaShop#{site_key.capitalize}EmployerProfile".constantize) || @resource.is_a?(BenefitSponsors::Organizations::FehbEmployerProfile)
    end

    def is_person?
      @resource.is_a?(Person)
    end

    def notice_upload_secure_message(resource, subject, body, document = nil)
      if document.present?
        body =  body + "<br>You can download the notice by clicking this link " +
          "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(resource.class.to_s,
                                                                                                 resource.id, 'documents', document.id )}?content_type=#{document.format}&filename=#{document.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + document.title.gsub(/[^0-9a-z]/i,'') + "</a>"
      end
      message = resource.inbox.messages.build({ subject: subject, body: body, from: site_short_name })
      message.save!
      Success(true)
    end

    def get_file_path(file)
      file.tempfile.path
    end

    def fetch_resource(params)
     resource =  if params[:person_id].present?
                  Person.find(params[:person_id])
                elsif params[:profile_id].present?
                  BenefitSponsors::Organizations::Profile.find(params[:profile_id])
                 end
     resource ? Success(resource) : Failure([:error, 'Resource not found'])
    end


    def file_content_type(params)
      params[:file].content_type
    end

    def file_name(params)
      params[:file].original_filename
    end

  end
end
