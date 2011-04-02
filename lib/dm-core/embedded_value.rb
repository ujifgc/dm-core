module DataMapper
  module EmbeddedValue
    include DataMapper::Assertions
    include Resource::RaiseOnSave
    include Resource::PersistedState
    include Resource::Hooks
    include Resource::Attributes
    include Resource::Operators

    extend Chainable

    # @api public
    attr_reader :parent_resource

    # TODO: shared with resource
    def repository_name
      model.repository_name
    end

    # @api public
    # TODO: shared with Resource
    alias_method :model, :class

    def self.included(model)
      model.extend Model
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

    private

    # @api private
    def lazy_load(properties)
      # noop
    end

    # @api public
    def initialize(attributes = nil, resource = nil)
      @parent_resource = resource   if resource
      self.attributes  = attributes if attributes
    end
  end
end
