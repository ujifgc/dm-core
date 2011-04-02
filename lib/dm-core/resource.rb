module DataMapper
  module Resource
    include DataMapper::Assertions
    include RaiseOnSave
    include PersistedState
    include Hooks
    include Attributes
    include Operators

    extend Chainable

    # Deprecated API for updating attributes and saving Resource
    #
    # @see #update
    #
    # @deprecated
    def update_attributes(attributes = {}, *allowed)
      raise "#{model}#update_attributes is deprecated, use #{model}#update instead (#{caller.first})"
    end

    # Makes sure a class gets all the methods when it includes Resource
    #
    # Note that including this module into an anonymous class will leave
    # the model descendant tracking mechanism with no possibility to reliably
    # track the anonymous model across code reloads. This means that
    # {DataMapper::DescendantSet} will currently leak memory in scenarios where
    # anonymous models are reloaded multiple times (as is the case in dm-rails
    # development mode for example).
    #
    # @api private
    def self.included(model)
      model.extend Model
    end

    # @api public
    alias_method :model, :class

    # Repository this resource belongs to in the context of this collection
    # or of the resource's class.
    #
    # @return [Repository]
    #   the respository this resource belongs to, in the context of
    #   a collection OR in the instance's Model's context
    #
    # @api semipublic
    def repository
      # only set @_repository explicitly when persisted
      defined?(@_repository) ? @_repository : model.repository
    end

    # Retrieve the key(s) for this resource.
    #
    # This always returns the persisted key value,
    # even if the key is changed and not yet persisted.
    # This is done so all relations still work.
    #
    # @return [Array(Key)]
    #   the key(s) identifying this resource
    #
    # @api public
    def key
      return @_key if defined?(@_key)

      model_key = model.key(repository_name)

      key = model_key.map do |property|
        original_attributes[property] || (property.loaded?(self) ? property.get!(self) : nil)
      end

      # only memoize a valid key
      @_key = key if model_key.valid?(key)
    end


    # Reloads association and all child association
    #
    # This is accomplished by resetting the Resource key to it's
    # original value, and then removing all the ivars for properties
    # and relationships.  On the next access of those ivars, the
    # resource will eager load what it needs.  While this is more of
    # a lazy reload, it should result in more consistent behavior
    # since no cached results will remain from the initial load.
    #
    # @return [Resource]
    #   the receiver, the current Resource instance
    #
    # @api public
    def reload
      if key
        reset_key
        clear_subjects
      end

      self.persisted_state = persisted_state.rollback

      self
    end

    # Updates attributes and saves this Resource instance
    #
    # @param [Hash] attributes
    #   attributes to be updated
    #
    # @return [Boolean]
    #   true if resource and storage state match
    #
    # @api public
    def update(attributes)
      assert_update_clean_only(:update)
      self.attributes = attributes
      save
    end

    # Updates attributes and saves this Resource instance, bypassing hooks
    #
    # @param [Hash] attributes
    #   attributes to be updated
    #
    # @return [Boolean]
    #   true if resource and storage state match
    #
    # @api public
    def update!(attributes)
      assert_update_clean_only(:update!)
      self.attributes = attributes
      save!
    end

    # Save the instance and loaded, dirty associations to the data-store
    #
    # @return [Boolean]
    #   true if Resource instance and all associations were saved
    #
    # @api public
    def save
      assert_not_destroyed(:save)
      retval = _save
      assert_save_successful(:save, retval)
      retval
    end

    # Save the instance and loaded, dirty associations to the data-store, bypassing hooks
    #
    # @return [Boolean]
    #   true if Resource instance and all associations were saved
    #
    # @api public
    def save!
      assert_not_destroyed(:save!)
      retval = _save(false)
      assert_save_successful(:save!, retval)
      retval
    end

    # Destroy the instance, remove it from the repository
    #
    # @return [Boolean]
    #   true if resource was destroyed
    #
    # @api public
    def destroy
      return true if destroyed?
      catch :halt do
        before_destroy_hook
        _destroy
        after_destroy_hook
      end
      destroyed?
    end

    # Destroy the instance, remove it from the repository, bypassing hooks
    #
    # @return [Boolean]
    #   true if resource was destroyed
    #
    # @api public
    def destroy!
      return true if destroyed?
      _destroy(false)
      destroyed?
    end

    # Returns hash value of the object.
    # Two objects with the same hash value assumed equal (using eql? method)
    #
    # DataMapper resources are equal when their models have the same hash
    # and they have the same set of properties
    #
    # When used as key in a Hash or Hash subclass, objects are compared
    # by eql? and thus hash value has direct effect on lookup
    #
    # @api private
    def hash
      model.hash ^ key.hash
    end

    # Returns the Collection the Resource is associated with
    #
    # @return [nil]
    #    nil if this is a new record
    # @return [Collection]
    #   a Collection that self belongs to
    #
    # @api private
    def collection
      return @_collection if @_collection || new? || readonly?
      collection_for_self
    end

    # Associates a Resource to a Collection
    #
    # @param [Collection, nil] collection
    #   the collection to associate the resource with
    #
    # @return [nil]
    #    nil if this is a new record
    # @return [Collection]
    #   a Collection that self belongs to
    #
    # @api private
    def collection=(collection)
      @_collection = collection
    end

    # Return a collection including the current resource only
    #
    # @return [Collection]
    #   a collection containing self
    #
    # @api private
    def collection_for_self
      Collection.new(query, [ self ])
    end

    # Returns a Query that will match the resource
    #
    # @return [Query]
    #   Query that will match the resource
    #
    # @api semipublic
    def query
      repository.new_query(model, :fields => fields, :conditions => conditions)
    end

    private

    # Initialize a new instance of this Resource using the provided values
    #
    # @param [Hash] attributes
    #   attribute values to use for the new instance
    #
    # @return [Hash]
    #   attribute values used in the new instance
    #
    # @api public
    def initialize(attributes = nil) # :nodoc:
      self.attributes = attributes if attributes
    end

    # @api private
    def initialize_copy(original)
      instance_variables.each do |ivar|
        instance_variable_set(ivar, DataMapper::Ext.try_dup(instance_variable_get(ivar)))
      end

      self.persisted_state = persisted_state.class.new(self)
    end

    # Returns name of the repository this object
    # was loaded from
    #
    # @return [String]
    #   name of the repository this object was loaded from
    #
    # @api private
    def repository_name
      repository.name
    end


    # Gets this instance's Model's relationships
    #
    # @return [RelationshipSet]
    #   List of this instance's Model's Relationships
    #
    # @api private
    def relationships
      model.relationships(repository_name)
    end

    # Returns the identity map for the model from the repository
    #
    # @return [IdentityMap]
    #   identity map of repository this object was loaded from
    #
    # @api private
    def identity_map
      repository.identity_map(model)
    end

    # @api private
    def add_to_identity_map
      identity_map[key] = self
    end

    # @api private
    def remove_from_identity_map
      identity_map.delete(key)
    end

    # Reset the key to the original value
    #
    # @return [undefined]
    #
    # @api private
    def reset_key
      properties.key.zip(key) do |property, value|
        property.set!(self, value)
      end
    end

    # Remove all the ivars for properties and relationships
    #
    # @return [undefined]
    #
    # @api private
    def clear_subjects
      model_properties = properties

      (model_properties - model_properties.key | relationships).each do |subject|
        next unless subject.loaded?(self)
        remove_instance_variable(subject.instance_variable_name)
      end
    end

    # Lazy loads attributes not yet loaded
    #
    # @param [Array<Property>] properties
    #   the properties to reload
    #
    # @return [self]
    #
    # @api private
    def lazy_load(properties)
      eager_load(properties - fields)
    end

    # Reloads specified attributes
    #
    # @param [Array<Property>] properties
    #   the properties to reload
    #
    # @return [Resource]
    #   the receiver, the current Resource instance
    #
    # @api private
    def eager_load(properties)
      unless properties.empty? || key.nil? || collection.nil?
        # set an initial value to prevent recursive lazy loads
        properties.each { |property| property.set!(self, nil) }

        collection.reload(:fields => properties)
      end

      self
    end

    # Return conditions to match the Resource
    #
    # @return [Hash]
    #   query conditions
    #
    # @api private
    def conditions
      key = self.key
      if key
        model.key_conditions(repository, key)
      else
        conditions = {}
        properties.each do |property|
          next unless property.loaded?(self)
          conditions[property] = property.get!(self)
        end
        conditions
      end
    end

    # @api private
    def parent_relationships
      parent_relationships = []

      relationships.each do |relationship|
        next unless relationship.respond_to?(:resource_for)
        set_default_value(relationship)
        next unless relationship.loaded?(self) && relationship.get!(self)

        parent_relationships << relationship
      end

      parent_relationships
    end

    # Returns loaded child relationships
    #
    # @return [Array<Associations::OneToMany::Relationship>]
    #   array of child relationships for which this resource is parent and is loaded
    #
    # @api private
    def child_relationships
      child_relationships = []

      relationships.each do |relationship|
        next unless relationship.respond_to?(:collection_for)
        set_default_value(relationship)
        next unless relationship.loaded?(self)

        child_relationships << relationship
      end

      many_to_many, other = child_relationships.partition do |relationship|
        relationship.kind_of?(Associations::ManyToMany::Relationship)
      end

      many_to_many + other
    end

    # @api private
    def parent_associations
      parent_relationships.map { |relationship| relationship.get!(self) }
    end

    # @api private
    def child_associations
      child_relationships.map { |relationship| relationship.get_collection(self) }
    end

    # Destroy the resource
    #
    # @return [undefined]
    #
    # @api private
    def _destroy(execute_hooks = true)
      self.persisted_state = persisted_state.delete
      _persist
    end

    # @api private
    def _save(execute_hooks = true)
      run_once(true) do
        save_parents(execute_hooks) && save_self(execute_hooks) && save_children(execute_hooks)
      end
    end

    # Saves the resource
    #
    # @return [Boolean]
    #   true if the resource was successfully saved
    #
    # @api semipublic
    def save_self(execute_hooks = true)
      # short-circuit if the resource is not dirty
      return saved? unless dirty_self?

      if execute_hooks
        new? ? create_with_hooks : update_with_hooks
      else
        _persist
      end
      clean?
    end

    # Saves the parent resources
    #
    # @return [Boolean]
    #   true if the parents were successfully saved
    #
    # @api private
    def save_parents(execute_hooks)
      run_once(true) do
        parent_relationships.map do |relationship|
          parent = relationship.get(self)

          if parent.__send__(:save_parents, execute_hooks) && parent.__send__(:save_self, execute_hooks)
            relationship.set(self, parent)  # set the FK values
          end
        end.all?
      end
    end

    # Saves the children resources
    #
    # @return [Boolean]
    #   true if the children were successfully saved
    #
    # @api private
    def save_children(execute_hooks)
      child_associations.map do |association|
        association.__send__(execute_hooks ? :save : :save!)
      end.all?
    end

    # Checks if the resource has unsaved changes
    #
    # @return [Boolean]
    #  true if the resource has unsaved changes
    #
    # @api semipublic
    def dirty_self?
      if original_attributes.any?
        true
      elsif new?
        !model.serial.nil? || properties.any? { |property| property.default? }
      else
        false
      end
    end

    # Checks if the parents have unsaved changes
    #
    # @return [Boolean]
    #  true if the parents have unsaved changes
    #
    # @api private
    def dirty_parents?
      run_once(false) do
        parent_associations.any? do |association|
          association.__send__(:dirty_self?) || association.__send__(:dirty_parents?)
        end
      end
    end

    # Checks if the children have unsaved changes
    #
    # @param [Hash] resources
    #   resources that have already been tested
    #
    # @return [Boolean]
    #  true if the children have unsaved changes
    #
    # @api private
    def dirty_children?
      child_associations.any? { |association| association.dirty? }
    end

    # Return true if +other+'s is equivalent or equal to +self+'s
    #
    # @param [Resource] other
    #   The Resource whose attributes are to be compared with +self+'s
    # @param [Symbol] operator
    #   The comparison operator to use to compare the attributes
    #
    # @return [Boolean]
    #   The result of the comparison of +other+'s attributes with +self+'s
    #
    # @api private
    def cmp?(other, operator)
      return false unless repository.send(operator, other.repository) &&
                          key.send(operator, other.key)

      if saved? && other.saved?
        # if dirty attributes match then they are the same resource
        dirty_attributes == other.dirty_attributes
      else
        # compare properties for unsaved resources
        properties.all? do |property|
          __send__(property.name).send(operator, other.__send__(property.name))
        end
      end
    end

    # @api private
    def set_default_value(subject)
      return unless persisted_state.respond_to?(:set_default_value, true)
      persisted_state.__send__(:set_default_value, subject)
    end

    # Raises an exception if #update is performed on a dirty resource
    #
    # @param [Symbol] method
    #   the name of the method to use in the exception
    #
    # @return [undefined]
    #
    # @raise [UpdateConflictError]
    #   raise if the resource is dirty
    #
    # @api private
    def assert_update_clean_only(method)
      if dirty?
        raise UpdateConflictError, "#{model}##{method} cannot be called on a #{new? ? 'new' : 'dirty'} resource"
      end
    end

    # Raises an exception if #save is performed on a destroyed resource
    #
    # @param [Symbol] method
    #   the name of the method to use in the exception
    #
    # @return [undefined]
    #
    # @raise [PersistenceError]
    #   raise if the resource is destroyed
    #
    # @api private
    def assert_not_destroyed(method)
      if destroyed?
        raise PersistenceError, "#{model}##{method} cannot be called on a destroyed resource"
      end
    end

    # Raises an exception if #save returns false
    #
    # @param [Symbol] method
    #   the name of the method to use in the exception
    # @param [Boolean] save_result
    #   the result of the #save call
    #
    # @return [undefined]
    #
    # @raise [SaveFailureError]
    #   raise if the resource was not saved
    #
    # @api private
    def assert_save_successful(method, save_retval)
      if save_retval != true && raise_on_save_failure
        raise SaveFailureError.new("#{model}##{method} returned #{save_retval.inspect}, #{model} was not saved", self)
      end
    end

    # Prevent a method from being in the stack more than once
    #
    # The purpose of this method is to prevent SystemStackError from
    # being thrown from methods from encountering infinite recursion
    # when called on resources having circular dependencies.
    #
    # @param [Object] default
    #   default return value
    #
    # @yield The block of code to run once
    #
    # @return [Object]
    #   block return value
    #
    # @api private
    def run_once(default)
      caller_method = Kernel.caller(1).first[/`([^'?!]+)[?!]?'/, 1]
      sentinel      = "@_#{caller_method}_sentinel"
      return instance_variable_get(sentinel) if instance_variable_defined?(sentinel)

      begin
        instance_variable_set(sentinel, default)
        yield
      ensure
        remove_instance_variable(sentinel)
      end
    end
  end # module Resource
end # module DataMapper
