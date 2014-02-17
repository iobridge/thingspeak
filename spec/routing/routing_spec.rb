require "spec_helper"

describe "routes for Widgets" do
  it "routes / to the pages controller" do
    { :get => "/" }.should route_to(:controller => "pages", :action => "home")
  end
  it "routes /channels/:id to the channels controller" do
    { :get => "/channels/1" }.should route_to(:controller => "channels", :action => "show", :id => "1")
  end
end


