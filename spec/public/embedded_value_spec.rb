require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe DataMapper::EmbeddedValue do
  class ::Address
    include DataMapper::EmbeddedValue

    property :street, String

    def an_instance_method
    end
  end

  class ::SubAddress < Address; end

  DataMapper.finalize

  before :all do
    @base_model = ::Address
    @sub_model  = ::SubAddress
    @resource   = @base_model.new
  end


  it_should_behave_like "a Model with properties"
  it_should_behave_like "a Model with hooks"

  describe "parent model" do
    let(:attributes) do
      { :street => "Foo Bar 12/34" }
    end

    before :all do
      class ::Address
        include DataMapper::EmbeddedValue

        property :street, String

        def an_instance_method
        end
      end

      class ::SubAddress < Address; end

      class ::User
        include DataMapper::Resource
        property :id,      Serial
        property :address, ::Address
      end

      DataMapper.finalize
    end

    describe "#attributes=" do
      let(:user) { ::User.new }

      before do
        user.attributes = { :address => attributes }
      end

      it "should set address embedded value" do
        user.address.should be_kind_of(::Address)
      end

      it "should set address attributes" do
        user.address.attributes.should == attributes
      end

      it "should mark user as dirty" do
        user.dirty?.should be(true)
      end

      it "should mark address as dirty" do
        pending do
          user.address.dirty?.should be(true)
        end
      end
    end

    supported_by :mongo do
      let(:user) { ::User.new(:address => attributes) }

      describe "#save" do
        it "should persist user with embedded address" do
          user.save.should be(true)
        end
      end

      describe "#first" do
        before :all do
          User.create(:address => attributes)
        end

        context "without conditions" do
          let(:user) { User.first }

          it "should return user with address" do
            user.address.should be_kind_of(::Address)
          end

          it "should return user with correct attributes" do
            user.address.attributes.should == attributes
          end
        end

        context "with conditions" do
          let(:user) { User.first :address => attributes }

          before { User.create :address => { :street => "Bar 123" } }

          it "should return correct user" do
            user.should_not be_nil
            user.address.attributes.should == attributes
          end
        end
      end
    end
  end
end
