class Envelope < PdfReport

  def initialize
    template = Rails.root.join('lib/pdf_templates', 'ivl_envelope.pdf')

    super({:template => template, :margin => [30, 55]})
    font_size 11

    @margin = [30, 70]
  end

  def fill_envelope(notice, mpi_indicator = nil)
    x_pos = mm2pt(21.83) - @margin[0]
    y_pos = 790.86 - mm2pt(57.15) - 65

    bounding_box([x_pos, y_pos], :width => 300) do
      fill_recipient_contact(notice)
    end

    x_pos = mm2pt(6.15)
    y_pos = 57

    if mpi_indicator.present?
      bounding_box([x_pos, y_pos], :width => 300) do
        text mpi_indicator
      end
    end
  end

  def fill_recipient_contact(notice)
    text notice.primary_fullname
    text notice.primary_address.street_1
    text notice.primary_address.street_2 unless notice.primary_address.street_2.blank?
    text "#{notice.primary_address.city}, #{notice.primary_address.state} #{notice.primary_address.zip}"      
  end
end