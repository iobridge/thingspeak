module ActionDispatch
  module Http
    module MimeNegotiation

      # Patched to always accept at least HTML
      def accepts
        @env["action_dispatch.request.accepts"] ||= begin
          header = @env['HTTP_ACCEPT'].to_s.strip

          if header.empty?
            [content_mime_type]
          else
            Mime::Type.parse(header) << Mime::HTML
          end
        end
      end

    end
  end
end

