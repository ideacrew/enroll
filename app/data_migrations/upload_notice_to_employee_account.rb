require File.join(Rails.root, "lib/mongoid_migration_task")

class UploadNoticeToEmployeeAccount < MongoidMigrationTask

  def migrate
    raise "HBX ID not present" if ENV['hbx_id'].blank?
    raise "Please enter the notice title" if ENV['notice_name'].blank?
    raise "Please specify file path" if ENV['file_path'].blank?

    notice_path = "#{ENV['file_path']}"
    notice_subject = ENV['notice_name']
    notice_title = ENV['notice_name'].titleize.gsub(/\s*/, '')

    person = Person.by_hbx_id(ENV['hbx_id']).first

    if person.present?
      upload_and_send_secure_message(person, notice_path, notice_title, notice_subject)
    else
      puts "No person found with the given HBX ID - #{ENV['hbx_id']}" unless Rails.env.test?
    end
  end

  def upload_and_send_secure_message(person, notice_path, notice_title, notice_subject)
    doc_uri = upload_to_amazonS3(notice_path)
    notice  = create_recipient_document(person, doc_uri, notice_title)
    create_secure_inbox_message(person, notice, notice_subject)
  end

  def upload_to_amazonS3(notice_path)
    Aws::S3Storage.save(notice_path, 'notices')
  rescue => e
    raise "Unable to upload to amazon due to #{e}"
  end

  def create_recipient_document(person, doc_uri, notice_title)
    notice = person.documents.build({
      title: notice_title,
      creator: "hbx_staff",
      subject: "notice",
      identifier: doc_uri,
      format: "application/pdf"
    })

    if notice.save
      notice
    else
      raise "Unable to save #{notice_title} notice to #{person.full_name}'s account"
    end
  end

  def create_secure_inbox_message(recipient, notice, notice_subject)
    body = "<br>You can download the notice by clicking this link " +
            "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s, 
              recipient.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + notice.title + "</a>"
    message = recipient.inbox.messages.build({ subject: notice_subject, body: body, from: "#{Settings.site.short_name}" })
    message.save!
  end
end