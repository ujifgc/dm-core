module DataMapper
  module EmbeddedValue
    module Model
      extend Chainable
      extend DataMapper::Model::Core

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

      # Return all models that inherit from a Model
      #
      #   class Foo
      #     include DataMapper::Resource
      #   end
      #
      #   class Bar < Foo
      #   end
      #
      #   Foo.descendants.first   #=> Bar
      #
      # @return [Set]
      #   Set containing the descendant classes
      #
      # @api semipublic
      def descendants
        @descendants ||= DescendantSet.new
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
          DataMapper::EmbeddedValue::Model.raise_on_save_failure
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

      # @api semipublic
      def load(fields, parent_resource)
        resource = new(fields, parent_resource)
        resource.persisted_state = Resource::State::Clean.new(resource)
        resource
      end

      append_extensions DataMapper::Model::Property, DataMapper::Property::Lookup
      append_inclusions DataMapper::Model::Hook
    end # Model
  end # EmbeddedValue
end # DataMapper
