# == Schema Information
# Schema version: 20100419121920
#
# Table name: transport_modes
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class TransportMode < ActiveRecord::Base
  has_many :stop_types
end
