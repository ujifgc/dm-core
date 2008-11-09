require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe DataMapper::Property do

  # define the model prior to with_adapters
  before do
    Object.send(:remove_const, :Track) if defined?(Track)
    class Track
      include DataMapper::Resource

      property :id,     Serial
      property :artist, String
      property :title,  String, :field => 'name'
      property :album,  String
    end
  end

  supported_by :all do
    describe "#field" do
      it "returns @field value if it is present"

      it 'returns field for specific repository when it is present'

      it 'sets field value using field naming convention on first reference'
    end

    describe "#unique" do
      it "is true for fields that explicitly given uniq index"

      it "is true for serial fields"

      it "is true for keys"
    end

    describe "#hash" do
      it 'triggers binding of unbound custom types'

      it 'concats hashes of model name and property name'
    end

    describe "#equal?" do
      it 'is true for properties with the same model and name'

      it 'is false for properties of different models'

      it 'is false for properties with different names'
    end

    describe "#length" do
      it 'returns upper bound for Range values'

      it 'returns value as is for integer values'
    end

    describe "#index" do
      it 'returns index name when property has an index'

      it 'returns nil when property has no index'
    end

    describe "#unique_index" do
      it 'returns true when property has unique index'

      it 'returns false when property has no unique index'
    end

    describe "#lazy?" do
      it 'returns true when property is lazy loaded'

      it 'returns false when property is not lazy loaded'
    end

    describe "#key?" do
      it 'returns true when property is a key'

      it 'returns true when property is a part of composite key'

      it 'returns false when property does not relate to a key'
    end

    describe "#serial?" do
      it 'returns true when property is serial (auto incrementing)'

      it 'returns false when property is NOT serial (auto incrementing)'
    end

    describe "#nullable?" do
      it 'returns true when property can accept nil as its value'

      it 'returns false when property nil value is prohibited for this property'
    end

    describe "#custom?" do
      it "is true for custom type fields (not provided by dm-core)"

      it "is false for core type fields (provided by dm-core)"
    end

    describe "#get" do
      it 'triggers loading for lazy loaded properties'

      it 'sets original value'

      it 'sets default value for new records with nil value'

      it 'returns property value'
    end

    describe "#get!" do
      it 'gets instance variable value from the resource directly'
    end

    describe "#set_original_value" do
      it 'sets original value of the property'

      it 'only sets original value unless it is already set'
    end

    describe "#set" do
      it 'triggers lazy loading for given resource'

      it 'type casts given value'

      it 'stores original value'

      it 'sets new property value'
    end

    describe "#set!" do
      it 'directly sets instance variable on given resource'
    end

    describe "#lazy_load" do
      it 'returns nil if given resource is a new record'

      it 'triggers load for a single lazy loaded property'

      it 'triggers load for a group of lazy loaded properties'
    end

    describe "#typecast" do
      describe "when type is able to do typecasting on it's own" do
        it 'delegates all the work to the type'
      end

      describe "when value is nil" do
        it 'returns value unchanged'
      end

      describe "when value is a Ruby primitive" do
        it 'returns value unchanged'
      end

      describe "when type primitive is a string" do
        it 'runs #to_s on the value'

        it 'returns a string'
      end

      describe "when type primitive is a float" do
        it 'runs #to_f on the value'

        it 'returns a float'
      end

      describe "when type primitive is an integer" do
        describe "and value only has digits in it" do
          it 'runs #to_i on the value'

          it 'returns an integer'
        end

        describe "and value is a string representation of a hex or octal integer" do
          it 'returns 0'

          it 'returns an integer'
        end

        describe "but value has non-digits and punctuation in it" do
          it "returns nil"
        end
      end

      describe "when type primitive is a BigDecimal" do
        it 'casts the value to BigDecimal'
      end

      describe "when type primitive is a DateTime" do
        describe "and value given as a hash with keys like :year, :month, etc" do
          it 'builds a DateTime instance from hash values'
        end

        describe "and value is a string" do
          it 'parses the string'
        end
      end

      describe "when type primitive is a Date" do
        describe "and value given as a hash with keys like :year, :month, etc" do
          it 'builds a Date instance from hash values'
        end

        describe "and value is a string" do
          it 'parses the string'
        end
      end

      describe "when type primitive is a Time" do
        describe "and value given as a hash with keys like :year, :month, etc" do
          it 'builds a Time instance from hash values'
        end

        describe "and value is a string" do
          it 'parses the string'
        end
      end

      describe "when type primitive is a Class" do
        it 'looks up constant in Property namespace'
      end
    end # #typecase


    describe "#default_for" do
      it 'returns default value for non-callables'

      it 'returns result of a call for callable values'
    end

    describe "value" do
      it 'returns value for core types'

      it 'triggers dump operation for custom types'
    end

    describe "#inspect" do
      it 'shows model name'

      it 'shows property name'
    end

    describe "#initialize" do
      describe "when unknown type is given" do
        it 'raises an exception'
      end

      it "stores model"

      it 'stores field name'

      it 'stores serial flag'

      it 'stores key value'

      it 'stores default value'

      it 'stores unique index value'

      describe "when tracking strategy is explicitly given" do
        it 'uses tracking strategy from options'
      end

      describe "when custom type has tracking stragegy" do
        it 'uses tracking strategy from type'
      end
    end
  end
end # DataMapper::Property