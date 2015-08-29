require 'prawn'

class Notice

  attr_accessor :from, :to, :subject, :template, :notice_data, :mkt_kind, :file_name

  def initialize(recipient, args = {})
    @template = args[:template]
    @notice_data = args[:notice_data]
    @email_notice = args[:email_notice] || true
    @pdf_notice = args[:pdf_notice] || true
    @mailer = args[:mailer] || ApplicationMailer
    @file_name = "notice.pdf"
  end

  def html
    ApplicationController.new.render_to_string({ 
      :template => @template,
      :layout => 'pdf_notice_layout',
      :locals => { notice: @notice }
    })
  end

  def pdf
    WickedPdf.new.pdf_from_string(
      self.html,
      margin:  {  
        top: 15,
        bottom: 40,
        left: 22,
        right: 22 
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
    notice_path = Rails.root.join('pdfs', @file_name)
    File.open(notice_path, 'wb') do |file|
      file << self.pdf
    end
    append_dc_rights(notice_path)
  end

  def save_html
    File.open(Rails.root.join('pdfs','notice.html'), 'wb') do |file|
      file << self.html
    end
  end

  def append_dc_rights(source)
    legal_rights = Rails.root.join('lib/pdf_templates', 'dchl_rights.pdf')
    join_pdfs([source, legal_rights])
  end

  def join_pdfs(pdfs)
    Prawn::Document.generate("result.pdf", {:page_size => 'LETTER', :skip_page_creation => true}) do |pdf|
      pdfs.each do |pdf_file|
        if File.exists?(pdf_file)
          pdf_temp_nb_pages = Prawn::Document.new(:template => pdf_file).page_count
          (1..pdf_temp_nb_pages).each do |i|
            pdf.start_new_page(:template => pdf_file, :template_page => i)
          end
        end
      end
    end
  end
end

