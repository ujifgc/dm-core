module DataMapper
  module EmbeddedValue
    include DataMapper::Assertions
    extend Chainable
    extend Deprecate

    # @api public
    attr_reader :parent_resource

    # TODO: shared with parent resource
    # @api private
    def persisted_state
      @_state ||= Resource::State::Transient.new(self)
    end

    # TODO: shared with parent resource
    # @api private
    def persisted_state=(state)
      @_state = state
    end

    # TODO: shared with resource
    def repository_name
      model.repository_name
    end

    # TODO: shared with resource
    # @api public
    def attributes=(attributes)
      model = self.model

      attributes.each do |name, value|
        case name
        when String, Symbol
          if model.public_method_defined?(setter = "#{name}=")
            __send__(setter, value)
          else
            raise ArgumentError, "The attribute '#{name}' is not accessible in #{model}"
          end
        when Associations::Relationship, Property
          self.persisted_state = persisted_state.set(name, value)
        end
      end
    end

    # TODO: figure out a way to handle lazy loading
    # @api public
    def attributes(key_on = :name)
      attributes = {}

      fields.each do |property|
        if model.public_method_defined?(name = property.name)
          key = case key_on
            when :name  then name
            when :field then property.field
            else             property
          end

          attributes[key] = __send__(name)
        end
      end

      attributes
    end

    # TODO: shared with resource
    # @api private
    def fields
      properties.select do |property|
        property.loaded?(self) || (new? && property.default?)
      end
    end

    # @api public
    # TODO: shared with Resource
    alias_method :model, :class

    def self.included(model)
      model.extend Model
    end

    # TODO: shared with Resource
    def properties
      model.properties(repository_name)
    end

    # TODO: implement me
    def save
      execute_hooks_for(:before, :save)
      execute_hooks_for(:before, :create)
      # noop
      execute_hooks_for(:after, :save)
      execute_hooks_for(:after, :create)
    end

    # TODO: implement me
    def create
      execute_hooks_for(:before, :create)
      # noop
      execute_hooks_for(:after, :create)
    end

    # TODO: implement me
    def update(*args)
      execute_hooks_for(:before, :update)
      # noop
      execute_hooks_for(:after, :update)
    end

    # TODO: implement me
    def destroy
      execute_hooks_for(:before, :destroy)
      # noop
      execute_hooks_for(:after, :destroy)
    end

    # TODO: shared with Resource
    def execute_hooks_for(type, name)
      model.hooks[name][type].each { |hook| hook.call(self) }
    end

    private

    # @api public
    def initialize(attributes = nil, resource = nil)
      @parent_resource = resource   if resource
      self.attributes  = attributes if attributes
    end
  end
end
