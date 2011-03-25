module DataMapper
  class Property
    class EmbeddedValue < Object
      accept_options :embedded_model

      attr_reader :embedded_model

      protected

      def initialize(model, name, options = {})
        super
        @embedded_model = options[:embedded_model]
      end
    end # class EmbeddedValue
  end # class Property
end # module DataMapper
