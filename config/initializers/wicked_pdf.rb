# WickedPdf.config = {
#    :wkhtmltopdf => '/usr/local/bin/wkhtmltopdf',
# #   #:layout => "pdf.html",
#    :exe_path => Rails.root.join('bin', 'wkhtmltopdf-amd64').to_s
# }

module WickedPdfHelper
  if Rails.env.development?
    if RbConfig::CONFIG['host_os'] =~ /linux/
      executable = RbConfig::CONFIG['host_cpu'] == 'x86_64' ? 'wkhtmltopdf_linux_x64' : 'wkhtmltopdf_linux_386'
    elsif RbConfig::CONFIG['host_os'] =~ /darwin/
      executable = 'wkhtmltopdf_darwin_386'
    else
      raise 'Invalid platform. Must be running linux or intel-based Mac OS.'
    end

    # WickedPdf.config = { exe_path: "/usr/local/bin/wkhtmltopdf" }
  end
end