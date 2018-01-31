class PdfReport < Prawn::Document
  include Prawn::Measurements

  def initialize(options={ })
    if options[:margin].nil?
      options.merge!(:margin => [50, 70])
    end
    
    super(options)
    
    font "Times-Roman"
    font_size 12
  end
  
  def text(text, options = { })
    if !options.has_key?(:align)
      options.merge!({ :align => :justify })
    end

    super text, options
  end
end
