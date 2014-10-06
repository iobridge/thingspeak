module PagesHelper
  def blog_entries
		blog = ''
    begin
			Timeout.timeout(5, Timeout::Error) do
				# get the blog data
				blog_url = "http://community.thingspeak.com"
				doc = Nokogiri::HTML(open(blog_url, "User-Agent" => "Ruby/#{RUBY_VERSION}").read)

				# parse out the html we need
				doc.css("img").remove
        doc.css("script").remove
        doc.css("iframe").remove
				doc.css("div.post").each_with_index do |d, i|
					# only show 3 posts
					if (i < 3)
						blog += d.css("h2").to_s
						blog += d.css("div.entry").to_s
						blog += "<hr>" if i != 2
					end
				end
			end
		rescue Timeout::Error
		rescue
		end
		blog
  end
end

