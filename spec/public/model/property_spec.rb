require 'spec_helper'

describe DataMapper::Model::Property do
  before do
    Object.send(:remove_const, :ModelPropertySpecs) if defined?(ModelPropertySpecs)
    class ::ModelPropertySpecs
      include DataMapper::Resource

      property :id, Serial
    end
    DataMapper.finalize
    @base_model = ::ModelPropertySpecs
  end

  it_should_behave_like "a Model with properties"
end
