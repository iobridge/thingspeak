#Changing the as_json method to remove the milliseconds from TimeWithZone to_json result (just like in Rails 3)
class ActiveSupport::TimeWithZone
  def as_json(options = {})
    if ActiveSupport::JSON::Encoding.use_standard_json_time_format
      xmlschema
    else
      %(#{time.strftime("%Y/%m/%d %H:%M:%S")} #{formatted_offset(false)})
    end
  end
end

