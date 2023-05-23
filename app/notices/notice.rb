class Notice

  include Config::AcaHelper
  include Config::SiteHelper
  include Config::ContactCenterHelper

  attr_accessor :from, :to, :options, :name, :subject, :template,:mpi_indicator, :event_name, :notice_data, :recipient_document_store ,:market_kind, :file_name, :notice , :random_str ,:recipient, :header, :sep, :state

  Required=[:subject,:mpi_indicator,:template,:recipient,:notice,:market_kind,:event_name,:recipient_document_store]

  def initialize(params = {})
    validate_params(params)
    self.subject = "#{params[:subject]}" || "notice_#{random_str}"
    self.mpi_indicator = params[:mpi_indicator]
    self.template = params[:template]
    self.notice= params[:notice]
    self.event_name= params[:event_name]
    self.market_kind= params[:market_kind]
    self.recipient= params[:recipient]
    self.recipient_document_store = params[:recipient_document_store]
    self.to = params[:to]
    self.state = params[:options][:state] if params[:options]
    self.name = params[:name] || recipient.first_name
    self.sep = params[:options][:sep] if params[:options]
  end

  def html(options = {})
    ApplicationController.new.render_to_string({
      :template => options[:custom_template] || template,
      :layout => layout,
      :locals => { notice: notice }
    })
  end

  def random_str
    @random_str ||= rand(10**10).to_s
  end

  def pdf
    WickedPdf.new.pdf_from_string(self.html({kind: 'pdf'}), pdf_options)
  end

  def layout
    if market_kind == 'individual'
      'ivl_pdf_notice'
    else
      'pdf_notice'
    end
  end

  def notice_filename
    "#{recipient.hbx_id}_#{subject.titleize.gsub(/[^0-9a-z]/i,'')}"
  end

  def title
    "#{subject.titleize.gsub(/[^0-9a-z]/i,'')}"
  end

  def notice_path
    Rails.root.join("tmp", "#{notice_filename}.pdf")
  end

  def envelope_path
    Rails.root.join("tmp", "envelope_#{random_str}.pdf")
  end

  def pdf_options
    options = {
      margin:  {
        top: 10,
        bottom: 20,
        left: 22,
        right: 22
      },
      disable_smart_shrinking: true,
      dpi: 96,
      page_size: 'Letter',
      formats: :html,
      encoding: 'utf8',
      header: {
        content: ApplicationController.new.render_to_string({
          template: header,
          layout: false,
          locals: {recipient: recipient, notice: notice}
          }),
        }
    }
    footer = (market_kind == "individual") ? "notices/shared/footer_ivl.html.erb" : "notices/shared/footer.html.erb"
      options.merge!({footer: {
        content: ApplicationController.new.render_to_string({
          template: footer,
          layout: false,
          locals: {notice: notice}
        })
      }})
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
    begin
      File.open(notice_path, 'wb') do |file|
        file << self.pdf
      end
    rescue Exception => e
      puts "#{e} #{e.backtrace}"
    end
    # notice_path
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

  # @param recipient is a Person object
  def send_generic_notice_alert
    UserMailer.generic_notice_alert(name,subject,to).deliver_now
  end

  def store_paper_notice
    bucket_name= Settings.paper_notice
    notice_filename_for_paper_notice = "#{recipient.hbx_id}_#{subject.titleize.gsub(/\s*/, '')}_#{mpi_indicator.delete('_')}_IVL"
    notice_path_for_paper_notice = Rails.root.join("tmp", "#{notice_filename_for_paper_notice}.pdf")
    begin
      FileUtils.cp(notice_path, notice_path_for_paper_notice)
      doc_uri = Aws::S3Storage.save(notice_path_for_paper_notice,bucket_name,"#{notice_filename_for_paper_notice}.pdf")
      File.delete(notice_path_for_paper_notice)
    rescue Exception => e
      puts "Unable to upload paper notices to Amazon"
    end
    # paper_notices_folder = "#{Rails.root.to_s}/public/paper_notices/"
    # FileUtils.cp(notice_path, "#{Rails.root.to_s}/public/paper_notices/")
    # File.rename(paper_notices_folder + , paper_notices_folder + "#{recipient.hbx_id}_" + notice_filename + File.extname(notice_path))
  end

  def create_recipient_document(doc_uri)
    notice = recipient_document_store.documents.build({
                                                        title: title,
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
            "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s,
              recipient.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + notice.title + "</a>"
    message = recipient.inbox.messages.build({ subject: subject, body: body, from: site_short_name })
    message.save!
  end

  def clear_tmp
    File.delete(envelope_path)
    File.delete(notice_path)
  end

  def validate_params(params)
    errors=[]
    self.class::Required.uniq.each do |key|
      next if params[key].present?
      errors << key
    end
    raise("Required params #{errors.join(' ,')} not present") if errors.present?
  end
end
