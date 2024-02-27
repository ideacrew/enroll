module NoticesHelper
  include HtmlScrubberUtil

  def notice_paragraph_with_disclaimer(content, disclaimer)
    html = "<div style='display:block; page-break-inside: avoid;'>"
    html << "<table class='total_table' border='0'><tbody>"
    html << notice_row_paragraph(content)
    html << "</tbody></table>"
    html << notice_disclaimer(disclaimer)
    html << "</div>"
    sanitize_html(html)
  end

  def notice_paragraph(content, options = {})
    html = "<div style='display:block; page-break-inside: avoid;'>"
    html << "<table class='total_table' border='0'><tbody>"
    html << notice_row_paragraph(content)
    html << "</tbody></table></div>"
    sanitize_html(html)
  end

  def notice_paragraph_with_heading(contents, heading)
    html = "<div style='display:block; page-break-inside: avoid;'>"
    html << "<table class='total_table' border='0'><tbody>"
    html << notice_paragraph_heading(heading)
    contents.each do |para|
      html << notice_row_paragraph(para)
    end
    html << "</tbody></table></div>"
    sanitize_html(html)
  end

  def notice_paragraph_heading(heading)
    html = "<h2 style='color:rgb(54,95,145);'>"
    html << heading
    html << "</h2>"
    sanitize_html(html)
  end

  def notice_row_paragraph(content)
    row = "<tr class='mar20 fssizeuser'><td>"
    row << content
    row << "</td></tr>"
    sanitize_html(row)
  end

  def notice_unordered_list(contents)
    html = "<table class='total_table' border='0'><tbody><tr><td>"
    html << "<ul style='list-style: circle solid;'>"
    contents.each do |line|
      html << "<li style='margin-top: 10px;'>"
      html << line
      html << "</li>"
    end
    html << "</ul></td></tr></tbody></table>"
    sanitize_html(html)
  end

  def notice_disclaimer(content)
    html = "<table class='total_table' border='0' style='font-size: 8px;'><tbody>"
    html << notice_row_paragraph(content)
    html << "</tbody></table>"
    sanitize_html(html)
  end
end