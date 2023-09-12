# https://github.com/roo-rb/roo/pull/392
# We would like to disable html injection to avoid surprises returning data with html tags upon reading XLSX file data
# AVOIDS: <html><u>THECONTACT@AGA.COM</u></html>
# RETURNS: THECONTACT@AGA.COM

module Roo
  class Excelx
    class SharedStrings < Excelx::Extractor
      def use_html?(_index)
        false
      end
    end
  end
end
