share_examples_for "a Model with properties" do
  describe DataMapper::Model::Property do
    let(:model) { @base_model.dup }

    it "should respond to #property" do
      model.should respond_to(:property)
    end

    describe '#property' do

      subject { model.property(:name, String) }

      it 'should define a name accessor' do
        model.should_not be_method_defined(:name)
        subject
        model.should be_method_defined(:name)
      end

      it 'should define a name= mutator' do
        model.should_not be_method_defined(:name=)
        subject
        model.should be_method_defined(:name=)
      end

      it 'should raise an exception if the method exists' do
        lambda {
          model.property(:key, String)
        }.should raise_error(ArgumentError, '+name+ was :key, which cannot be used as a property name since it collides with an existing method or a query option')
      end
    end
  end
end
