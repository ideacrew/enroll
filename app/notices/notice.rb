class Notice

  attr_accessor :from, :to, :subject, :template, :notice_data, :mkt_kind, :file_name, :notice , :random_str

  def initialize(args = {})
    @subject = "#{args[:subject]}" || "notice_#{random_str}"
    @mpi_indicator = args[:mpi_indicator]
    @template = arag[:template]
    @layout = 'pdf_notice'
  end

  def html(options = {})
    # notice_layout = 'bootstrap_email'
    # notice_layout = 'boiler_plate_email'
    ApplicationController.new.render_to_string({ 
      :template => @template,
      :layout => @layout,
      :locals => { notice: @notice }
    })
  end

  def random_str
    @random_str ||= rand(10**10).to_s
  end

  def pdf
    WickedPdf.new.pdf_from_string(self.html({kind: 'pdf'}), pdf_options)
  end

  def notice_filename
    "#{subject.titleize.gsub(/\s*/, '')}"
  end

  def notice_path
    Rails.root.join("tmp", "#{notice_filename}.pdf")
  end

  def envolope_path 
    Rails.root.join("tmp", "envelope_#{random_str}.pdf")
  end

  def pdf_options
    options = {
      margin:  {
        top: 15,
        bottom: 28,
        left: 22,
        right: 22 
      },
      disable_smart_shrinking: true,
      dpi: 96,
      page_size: 'Letter',
      formats: :html,
      encoding: 'utf8'
    }

    if @market_kind == 'individual'
      options.merge!({footer: { 
        content: ApplicationController.new.render_to_string({ 
          template: "notices/shared/footer.html.erb", 
          layout: false 
        })
      }})
    end
    
    options
  end

  def send_email_notice
    ApplicationMailer.notice_email(self).deliver_now
  end

  def save_html
    File.open(Rails.root.join("tmp", "notice.html"), 'wb') do |file|
      file << self.html
    end
  end

  def generate_pdf_notice
    File.open(notice_path, 'wb') do |file|
      file << self.pdf
    end
    # clear_tmp
  end

  def join_pdfs(pdfs)
    pdf = File.exists?(pdfs[0]) ? CombinePDF.load(pdfs[0]) : CombinePDF.new
    pdf << CombinePDF.load(pdfs[1])
    pdf.save notice_path
  end

  def upload_and_send_secure_message
    doc_uri = upload_to_amazonS3
    notice  = create_recipient_document(doc_uri)
    create_secure_inbox_message(notice)
  end
  
  def upload_to_amazonS3
    Aws::S3Storage.save(notice_path, 'notices')
  rescue => e
    raise "unable to upload to amazon #{e}"
  end

  #NOTE : This is a generic method to send secure message 
  # @param recipient is a SecureMessageRecipient object
  def send_generic_notice_alert(recipient)
    UserMailer.generic_notice_alert(recipient.name,subject, recipient.email_address).deliver_now
  end

  def store_paper_notice
    paper_notices_folder = "#{Rails.root.to_s}/public/paper_notices/"
    FileUtils.cp(notice_path, "#{Rails.root.to_s}/public/paper_notices/")
    File.rename(paper_notices_folder + "#{notice_filename}.pdf", paper_notices_folder + "#{recipient.hbx_id}_" + notice_filename + File.extname(notice_path))
  end

  def create_recipient_document(doc_uri)
    notice = family.documents.build({
      title: notice_filename, 
      creator: "hbx_staff",
      subject: "notice",
      identifier: doc_uri,
      format: "application/pdf"
    })

    if notice.save
      notice
    else
      # LOG ERROR
    end
  end

  def create_secure_inbox_message(notice)
    body = "<br>You can download the notice by clicking this link " +
            "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(@family.class.to_s, @family.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + notice.title + "</a>"
    message = recipient.inbox.messages.build({ subject: subject, body: body, from: 'DC Health Link' })
    message.save!
  end

  def clear_tmp
    File.delete(@envelope_path)
    File.delete(@notice_path)
  end
end
