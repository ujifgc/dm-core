require 'spec_helper'

describe DataMapper::Model do
  before :all do
    @model   = DataMapper::Model
    @include = DataMapper::Resource
  end

  it_should_behave_like "A semipublic Model"
end
