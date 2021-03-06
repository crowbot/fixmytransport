# == Schema Information
# Schema version: 20100707152350
#
# Table name: stop_area_types
#
#  id          :integer         not null, primary key
#  code        :string(255)
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

class StopAreaType < ActiveRecord::Base
  has_many :transport_mode_stop_area_types
  has_many :transport_modes, :through => :transport_mode_stop_area_types
  @@codes_by_mode = {}
  @@modes_by_code = {}
  @@station_types = ['GRLS', 'GTMU']
  @@bus_station_types = ['GBCS']
  @@ferry_terminal_types = ['GFTD']
  @@primary_types = @@station_types + @@ferry_terminal_types + @@bus_station_types
  @@atomic_types = @@station_types + @@ferry_terminal_types
  cattr_accessor :station_types,
                 :ferry_terminal_types,
                 :bus_station_types,
                 :primary_types,
                 :atomic_types

  def self.codes
    connection.select_rows("SELECT DISTINCT description, code
                            FROM stop_area_types
                            ORDER BY code")
  end

  def self.codes_for_transport_mode(transport_mode_id)
    calculate_hashes if @@codes_by_mode.empty?
    @@codes_by_mode[transport_mode_id]
  end

  def self.calculate_hashes
    transport_mode_stop_area_types = TransportModeStopAreaType.find(:all, :include => :stop_area_type)
    transport_mode_stop_area_types.each do |tmst|
      if ! @@codes_by_mode[tmst.transport_mode_id]
        @@codes_by_mode[tmst.transport_mode_id] = []
      end
      @@codes_by_mode[tmst.transport_mode_id] << tmst.stop_area_type.code
      if ! @@modes_by_code[tmst.stop_area_type.code]
        @@modes_by_code[tmst.stop_area_type.code] = []
      end
      @@modes_by_code[tmst.stop_area_type.code] << tmst.transport_mode_id
    end
  end

  def self.transport_modes_for_code(code)
    calculate_hashes if @@modes_by_code.empty?
    @@modes_by_code[code]
  end

  def self.conditions_for_transport_mode(transport_mode_id)
    if transport_mode_id == TransportMode.find_by_name("Tram/Metro").id
      codes = ['GTMU']
    else
      codes = codes_for_transport_mode(transport_mode_id).uniq
    end
    ['area_type in (?)', [codes]]
  end

end
