class Notice

  attr_accessor :from, :to, :subject, :template, :notice_data, :mkt_kind

  def initialize(recipient, args = {})
    @template = args[:template]
    @notice_data = args[:notice_data]
    @email_notice = args[:email_notice] || true
    @pdf_notice = args[:pdf_notice] || true
    @mailer = args[:mailer] || ApplicationMailer
  end

  def html
    ApplicationController.new.render_to_string({ 
      :template => @template,
      :layout => 'ivl_layout',
      :locals => { notice: @notice }
    })
  end

  def pdf
    WickedPdf.new.pdf_from_string(
      self.html,
      margin:  {  
        top: 10,
        bottom: 30,
        left: 25,
        right: 25 
      },
      page_size: 'Letter',
      formats: :html, 
      encoding: 'utf8',
      footer: { 
        content: ApplicationController.new.render_to_string( { template: "notices/ivl/footer.html.erb", layout: false }) 
      }
    )
  end

  def deliver
    send_email_notice if @email_notice
    send_pdf_notice if @paper_notice
  end

  def send_email_notice
    @mailer.notice_email(self).deliver_now
  end

  def send_pdf_notice
    notice_path = Rails.root.join('pdfs','notice.pdf')
    File.open(notice_path, 'wb') do |file|
      file << self.pdf
    end

    join_pdf = CombinePDF.new
    join_pdf << CombinePDF.load(notice_path)
    join_pdf << CombinePDF.load(Rails.root.join('lib/pdf_templates', 'dchl_rights.pdf'))

    join_pdf.save "notice_template.pdf"
  end

  def save_html
    File.open(Rails.root.join('pdfs','notice.html'), 'wb') do |file|
      file << self.html
    end
  end
end

