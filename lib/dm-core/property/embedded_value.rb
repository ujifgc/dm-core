module DataMapper
  class Property
    class EmbeddedValue < Object
      accept_options :embedded_model

      attr_reader :embedded_model

      def set(resource, attributes)
        set!(resource, typecast(attributes, resource))
      end

      def typecast(attributes, resource)
        if attributes.kind_of?(embedded_model)
          attributes
        else
          embedded_model.new(attributes, resource)
        end
      end

      protected

      def initialize(model, name, options = {})
        super
        @embedded_model = options[:embedded_model]
      end
    end # class EmbeddedValue
  end # class Property
end # module DataMapper
