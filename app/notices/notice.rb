class Notice

  attr_accessor :from, :to, :subject, :template, :notice_data, :mkt_kind, :file_name

  def initialize(recipient, args = {})
    @template = args[:template]
    @notice_data = args[:notice_data]
    @email_notice = args[:email_notice] || true
    @pdf_notice = args[:pdf_notice] || true
    @mailer = args[:mailer] || ApplicationMailer
    @blank_sheet_path = Rails.root.join('lib/pdf_pages', 'blank.pdf')
    @envelope_path = Rails.root.join('pdfs', 'envelope.pdf')
    @voter_registration = Rails.root.join('lib/pdf_pages', 'voter_application.pdf')
    @dchl_rights = Rails.root.join('lib/pdf_templates', 'dchl_rights.pdf')
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
        bottom: 30,
        left: 22,
        right: 22 
        },
        disable_smart_shrinking: true,
        dpi: 96,
        page_size: 'Letter',
        formats: :html,
        encoding: 'utf8',
        footer: { 
          content: ApplicationController.new.render_to_string({ 
            template: "notices/ivl/footer.html.erb", 
            layout: false 
            })
        })
  end

  def send_email_notice
    @mailer.notice_email(self).deliver_now
  end

  def save_html
    File.open(Rails.root.join('pdfs','notice.html'), 'wb') do |file|
      file << self.html
    end
  end

  def generate_pdf_notice
    File.open(@notice_path, 'wb') do |file|
      file << self.pdf
    end
  end

  def attach_blank_page
    page_count = Prawn::Document.new(:template => @notice_path).page_count
    if (page_count % 2) == 1
      join_pdfs [@notice_path, @blank_sheet_path]
    end
  end

  def attach_dchl_rights
    join_pdfs [@notice_path, @dchl_rights]
  end

  def attach_voter_registration
    join_pdfs [@notice_path, @voter_registration]
  end

  def prepend_envelope
    generate_envelope
    join_pdfs [@envelope_path, @notice_path]
  end

  private

  def generate_envelope
    envelope = Notices::Envelope.new 
    envelope.fill_envelope(@notice)
    envelope.render_file(@envelope_path)
  end

  def join_pdfs(pdfs)
    Prawn::Document.generate(@notice_path, {:page_size => 'LETTER', :skip_page_creation => true}) do |pdf|
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

