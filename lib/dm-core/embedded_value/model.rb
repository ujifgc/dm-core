module DataMapper
  module EmbeddedValue
    module Model
      extend Chainable

      include Enumerable

      # @api semipublic
      # TODO: shared with Resource
      attr_reader :base_model

      # Creates a new Model class with default_storage_name +storage_name+
      #
      # If a block is passed, it will be eval'd in the context of the new Model
      #
      # @param [Proc] block
      #   a block that will be eval'd in the context of the new Model class
      #
      # @return [Model]
      #   the newly created Model class
      #
      # @api semipublic
      def self.new(attributes, resource, &block)
        model = Class.new

        model.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        include DataMapper::EmbeddedValue

        def self.name
          to_s
        end

        def self.repository_name
          #{resource.model.repository_name}
        end
        RUBY

        model.instance_eval(&block) if block
        model
      end

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
      def self.descendants
        @descendants ||= DescendantSet.new
      end

      # Return all models that inherit from a Model
      #
      #   class Foo
      #     include DataMapper::Resource
      #   end
      #
      #   class Bar < Foo
      #   end
      #end
      #   Foo.descendants.first   #=> Bar
      #
      # @return [Set]
      #   Set containing the descendant classes
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
      def self.raise_on_save_failure
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
      def self.raise_on_save_failure=(raise_on_save_failure)
        @raise_on_save_failure = raise_on_save_failure
      end

      # Return if Resource#save should raise an exception on save failures (per-model)
      #
      # This delegates to DataMapper::Model.raise_on_save_failure by default.
      #
      #   User.raise_on_save_failure  # => false
      #
      # @return [Boolean]
      #   true if a failure in Resource#save should raise an exception
      #
      # @api public
      def raise_on_save_failure
        if defined?(@raise_on_save_failure)
          @raise_on_save_failure
        else
          DataMapper::Model.raise_on_save_failure
        end
      end

      # Specify if Resource#save should raise an exception on save failures (per-model)
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
      def self.append_inclusions(*inclusions)
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
      def self.extra_inclusions
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
      def self.append_extensions(*extensions)
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
      def self.extra_extensions
        @extra_extensions ||= []
      end

      # @api private
      def self.extended(descendant)
        descendants << descendant

        descendant.instance_variable_set(:@valid,      false)
        descendant.instance_variable_set(:@base_model, descendant)

        descendant.extend(Chainable)

        extra_extensions.each { |mod| descendant.extend(mod)         }
        extra_inclusions.each { |mod| descendant.send(:include, mod) }
      end

      # @api private
      chainable do
        def inherited(descendant)
          descendants << descendant

          descendant.instance_variable_set(:@valid,      false)
          descendant.instance_variable_set(:@base_model, base_model)
        end
      end

      # @api private
      # TODO: Remove this once appropriate warnings can be added.
      def assert_valid(force = false) # :nodoc:
        return if @valid && !force
        @valid = true

        name = self.name

        if properties(repository_name).empty? &&
            !relationships(repository_name).any? { |(relationship_name, relationship)| relationship.kind_of?(Associations::ManyToOne::Relationship) }
          raise IncompleteModelError, "#{name} must have at least one property or many to one relationship to be valid"
        end

        # initialize join models and target keys
        @relationships.values.each do |relationships|
          relationships.values.each do |relationship|
            relationship.child_key
            relationship.through if relationship.respond_to?(:through)
            relationship.via     if relationship.respond_to?(:via)
          end
        end
      end

      # TODO: implement me
      # @api private
      def repository_name
        :default
      end

      # TODO: implement me
      # @api private
      def default_repository_name
        :default
      end

      append_extensions DataMapper::Model::Property, Property::Lookup
      append_inclusions DataMapper::Model::Hook
    end # Model
  end # EmbeddedValue
end # DataMapper
