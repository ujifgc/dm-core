module DataMapper
  module Model
    module Core
      # Return all models that extend the Model module
      #
      #   class Foo
      #     include DataMapper::Resource
      #   end
      #
      #   DataMapper::Model.descendants.first   #=> Foo
      #
      # @return [DescendantSet]
      #   Set containing the descendant models
      #
      # @api semipublic
      def descendants
        @descendants ||= DescendantSet.new
      end

      # Return if Resource#save should raise an exception on save failures (globally)
      #
      # This is false by default.
      #
      #   DataMapper::Model.raise_on_save_failure  # => false
      #
      # @return [Boolean]
      #   true if a failure in Resource#save should raise an exception
      #
      # @api public
      def raise_on_save_failure
        if defined?(@raise_on_save_failure)
          @raise_on_save_failure
        else
          false
        end
      end

      # Specify if Resource#save should raise an exception on save failures (globally)
      #
      # @param [Boolean]
      #   a boolean that if true will cause Resource#save to raise an exception
      #
      # @return [Boolean]
      #   true if a failure in Resource#save should raise an exception
      #
      # @api public
      def raise_on_save_failure=(raise_on_save_failure)
        @raise_on_save_failure = raise_on_save_failure
      end

      # Appends a module for inclusion into the model class after Resource.
      #
      # This is a useful way to extend Resource while still retaining a
      # self.included method.
      #
      # @param [Module] inclusions
      #   the module that is to be appended to the module after Resource
      #
      # @return [Boolean]
      #   true if the inclusions have been successfully appended to the list
      #
      # @api semipublic
      def append_inclusions(*inclusions)
        extra_inclusions.concat inclusions

        # Add the inclusion to existing descendants
        descendants.each do |model|
          inclusions.each { |inclusion| model.send :include, inclusion }
        end

        true
      end

      # The current registered extra inclusions
      #
      # @return [Set]
      #
      # @api private
      def extra_inclusions
        @extra_inclusions ||= []
      end

      # Extends the model with this module after Resource has been included.
      #
      # This is a useful way to extend Model while still retaining a self.extended method.
      #
      # @param [Module] extensions
      #   List of modules that will extend the model after it is extended by Model
      #
      # @return [Boolean]
      #   whether or not the inclusions have been successfully appended to the list
      #
      # @api semipublic
      def append_extensions(*extensions)
        extra_extensions.concat extensions

        # Add the extension to existing descendants
        descendants.each do |model|
          extensions.each { |extension| model.extend(extension) }
        end

        true
      end

      # The current registered extra extensions
      #
      # @return [Set]
      #
      # @api private
      def extra_extensions
        @extra_extensions ||= []
      end

      # @api private
      def extended(descendant)
        descendants << descendant

        descendant.instance_variable_set(:@valid,         false)
        descendant.instance_variable_set(:@base_model,    descendant)
        descendant.instance_variable_set(:@storage_names, {})
        descendant.instance_variable_set(:@default_order, {})

        descendant.extend(Chainable)

        extra_extensions.each { |mod| descendant.extend(mod)         }
        extra_inclusions.each { |mod| descendant.send(:include, mod) }
      end
    end
  end # Model
end # DataMapper
