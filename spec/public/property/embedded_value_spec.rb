require 'spec_helper'

describe DataMapper::Property::EmbeddedValue do
  before :all do
    class Address
      include DataMapper::EmbeddedValue

      property :street, String
      property :zip,    String
    end

    class User
      include DataMapper::Resource

      property :id,      Serial
      property :address, Address
    end
  end

  it "should use Property::EmbeddedValue for the property class" do
    User.address.should be_kind_of(DataMapper::Property::EmbeddedValue)
  end

  it "should set :embedded_model" do
    User.address.embedded_model.should be(Address)
  end
end
