# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  class SecureMessage
    send(:include, Dry::Monads[:result, :do])

    include Config::SiteConcern

    def call(params: )
      person = yield fetch_person(params[:person][:person_id])
      if params[:file].present?
        doc_uri = yield upload_file_to_aws(params[:file])
        notice_document = yield create_notice_document_object(params, person, doc_uri)
      end
      notice_upload_email(person)
      notice_upload_secure_message(person, params[:subject], params[:body], notice_document)
      Success(person)
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

    def create_notice_document_object(params, person,uri)
      notice_document = Document.new({title: file_name(params), creator: "hbx_staff", subject: "notice", identifier: uri,
                                      format: file_content_type(params)})
      person.documents << notice_document
      person.save!
      Success(notice_document)
    end

    def notice_upload_email(person)
      if (person.consumer_role.present? && person.consumer_role.can_receive_electronic_communication?) ||
        (person.employee_roles.present? && (person.employee_roles.map(&:contact_method) & ["Only Electronic communications", "Paper and Electronic communications"]).any?)
        UserMailer.generic_notice_alert(person.first_name, "You have a new message from #{site_short_name}", person.work_email_or_best).deliver_now
      end
      Success(true)
    end

    def notice_upload_secure_message(person, subject, body, document = nil)
      if document.present?
        body =  body + "<br>You can download the notice by clicking this link " +
          "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path('Person', person.id, 'documents', document.id )}?content_type=#{document.format}&filename=#{document.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + subject + "</a>"

      end
      person.inbox.messages << Message.new(subject: subject, body: body, from: site_short_name)
      person.save!
      Success(true)
    end

    def get_file_path(file)
      file.tempfile.path
    end


    def file_content_type(params)
      params[:file].content_type
    end

    def file_name(params)
      params[:file].original_filename
    end

  end
end
