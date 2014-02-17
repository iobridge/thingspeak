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

require 'spec_helper'

describe Pipe do

end

