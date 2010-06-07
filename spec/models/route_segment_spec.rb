require 'spec_helper'

describe RouteSegment do
  before(:each) do
    @valid_attributes = {
      :from_stop_id => 1,
      :to_stop_id => 1,
      :from_terminus => false,
      :to_terminus => false,
      :route_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    RouteSegment.create!(@valid_attributes)
  end
end