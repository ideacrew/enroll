class Notice

  attr_accessor :from, :to, :subject, :template, :notice_data, :mkt_kind, :file_name

  def initialize(recipient, args = {})
    @notice_path = Rails.root.join('pdfs', 'notice.pdf')
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

  def pdf
    WickedPdf.new.pdf_from_string(
      self.html({kind: 'pdf'}),
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
            template: "notices/shared/footer.html.erb", 
            layout: false 
            })
        })
  end

  def send_email_notice
    ApplicationMailer.notice_email(self).deliver_now
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
end

class ShopPdfNotice < Notice
end
