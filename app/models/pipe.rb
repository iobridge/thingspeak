# == Schema Information
#
# Table name: pipes
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  url        :string(255)      not null
#  slug       :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#  parse      :string(255)
#  cache      :integer
#

class Pipe < ActiveRecord::Base

  # pagination variables
  cattr_reader :per_page
  @@per_page = 50

end

