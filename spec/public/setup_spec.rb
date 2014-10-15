require 'spec_helper'

describe DataMapper do
  describe '.setup' do
    describe 'using options' do
      before :all do
        @return = DataMapper.setup(:setup_test, :adapter => :in_memory, :foo => 'bar')

        @options = @return.options
      end

      after :all do
        DataMapper::Repository.adapters.delete(@return.name)
      end

      it 'should return an Adapter' do
        @return.should be_kind_of(DataMapper::Adapters::AbstractAdapter)
      end

      it 'should set up the repository' do
        DataMapper.repository(:setup_test).adapter.should equal(@return)
      end

      {
        :adapter => :in_memory,
        :foo     => 'bar'
      }.each do |key, val|
        it "should set the #{key.inspect} option" do
          @options[key].should == val
        end
      end
    end

    describe 'using invalid options' do
      it 'should raise an exception' do
        lambda {
          DataMapper.setup(:setup_test, :invalid)
        }.should raise_error(ArgumentError, '+options+ should be Hash, but was Symbol')
      end
    end

    describe 'using an instance of an adapter' do
      before :all do
        @adapter = DataMapper::Adapters::InMemoryAdapter.new(:setup_test)

        @return = DataMapper.setup(@adapter)
      end

      after :all do
        DataMapper::Repository.adapters.delete(@return.name)
      end

      it 'should return an Adapter' do
        @return.should be_kind_of(DataMapper::Adapters::AbstractAdapter)
      end

      it 'should set up the repository' do
        DataMapper.repository(:setup_test).adapter.should equal(@return)
      end

      it 'should use the adapter given' do
        @return.should == @adapter
      end

      it 'should use the name given to the adapter' do
        @return.name.should == @adapter.name
      end
    end

    supported_by :postgres, :mysql, :sqlite3, :sqlserver do
      { :path => :database, :user => :username }.each do |original_key, new_key|
        describe "using #{new_key.inspect} option" do
          before :all do
            @return = DataMapper.setup(:setup_test, :adapter => @adapter.options[:adapter], new_key => @adapter.options[original_key])

            @options = @return.options
          end

          after :all do
            DataMapper::Repository.adapters.delete(@return.name)
          end

          it 'should return an Adapter' do
            @return.should be_kind_of(DataMapper::Adapters::AbstractAdapter)
          end

          it 'should set up the repository' do
            DataMapper.repository(:setup_test).adapter.should equal(@return)
          end

          it "should set the #{new_key.inspect} option" do
            @options[new_key].should == @adapter.options[original_key]
          end
        end
      end
    end
  end
end
