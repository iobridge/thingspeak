class ErrorResponse

  def initialize(error_code)
    error_object = I18n.t(:error_codes)[error_code]
    @error_code = error_code.to_s
    @http_status = error_object[:http_status]
    @message = error_object[:message]
    @details = error_object[:details]
  end

  # attributes that can be read
  attr_reader :error_code, :http_status, :message, :details

  # custom json format
  def as_json(options = nil)
    {
      :status => "#{http_status}",
      :error => {
        :error_code => error_code,
        :message => message,
        :details => details
      }
    }
  end

  # custom xml format
  def to_xml
    output = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    output += "<hash>\n"
    output += "  <status>#{http_status}</status>\n"
    output += "  <error>\n"
    output += "    <error-code>#{error_code}</error-code>\n"
    output += "    <message>#{message}</message>\n"
    output += "    <details>#{details}</details>\n"
    output += "  </error>\n"
    output += "</hash>"
    return output
  end

end

