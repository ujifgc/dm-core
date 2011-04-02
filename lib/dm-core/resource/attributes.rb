module DataMapper
  module Resource
    module Attributes
      # Returns the value of the attribute.
      #
      # Do not read from instance variables directly, but use this method.
      # This method handles lazy loading the attribute and returning of
      # defaults if nessesary.
      #
      # @example
      #   class Foo
      #     include DataMapper::Resource
      #
      #     property :first_name, String
      #     property :last_name,  String
      #
      #     def full_name
      #       "#{attribute_get(:first_name)} #{attribute_get(:last_name)}"
      #     end
      #
      #     # using the shorter syntax
      #     def name_for_address_book
      #       "#{last_name}, #{first_name}"
      #     end
      #   end
      #
      # @param [Symbol] name
      #   name of attribute to retrieve
      #
      # @return [Object]
      #   the value stored at that given attribute
      #   (nil if none, and default if necessary)
      #
      # @api public
      def attribute_get(name)
        persisted_state.get(properties[name])
      end

      alias_method :[], :attribute_get

      # Sets the value of the attribute and marks the attribute as dirty
      # if it has been changed so that it may be saved. Do not set from
      # instance variables directly, but use this method. This method
      # handles the lazy loading the property and returning of defaults
      # if nessesary.
      #
      # @example
      #   class Foo
      #     include DataMapper::Resource
      #
      #     property :first_name, String
      #     property :last_name,  String
      #
      #     def full_name(name)
      #       name = name.split(' ')
      #       attribute_set(:first_name, name[0])
      #       attribute_set(:last_name, name[1])
      #     end
      #
      #     # using the shorter syntax
      #     def name_from_address_book(name)
      #       name = name.split(', ')
      #       first_name = name[1]
      #       last_name = name[0]
      #     end
      #   end
      #
      # @param [Symbol] name
      #   name of attribute to set
      # @param [Object] value
      #   value to store
      #
      # @return [undefined]
      #
      # @api public
      def attribute_set(name, value)
        self.persisted_state = persisted_state.set(properties[name], value)
      end

      alias_method :[]=, :attribute_set

      # Gets all the attributes of the Resource instance
      #
      # @param [Symbol] key_on
      #   Use this attribute of the Property as keys.
      #   defaults to :name. :field is useful for adapters
      #   :property or nil use the actual Property object.
      #
      # @return [Hash]
      #   All the attributes
      #
      # @api public
      def attributes(key_on = :name)
        attributes = {}

        lazy_load(properties)
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

      # Assign values to multiple attributes in one call (mass assignment)
      #
      # @param [Hash] attributes
      #   names and values of attributes to assign
      #
      # @return [Hash]
      #   names and values of attributes assigned
      #
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

      # Get a Human-readable representation of this Resource instance
      #
      #   Foo.new   #=> #<Foo name=nil updated_at=nil created_at=nil id=nil>
      #
      # @return [String]
      #   Human-readable representation of this Resource instance
      #
      # @api public
      def inspect
        # TODO: display relationship values
        attrs = properties.map do |property|
          value = if new? || property.loaded?(self)
                    property.get!(self).inspect
                  else
                    '<not loaded>'
                  end

          "#{property.instance_variable_name}=#{value}"
        end

        "#<#{model.name} #{attrs.join(' ')}>"
      end

      # Hash of original values of attributes that have unsaved changes
      #
      # @return [Hash]
      #   original values of attributes that have unsaved changes
      #
      # @api semipublic
      def original_attributes
        if persisted_state.respond_to?(:original_attributes)
          persisted_state.original_attributes.dup.freeze
        else
          {}.freeze
        end
      end

      # Checks if an attribute has been loaded from the repository
      #
      # @example
      #   class Foo
      #     include DataMapper::Resource
      #
      #     property :name,        String
      #     property :description, Text,   :lazy => false
      #   end
      #
      #   Foo.new.attribute_loaded?(:description)   #=> false
      #
      # @return [Boolean]
      #   true if ivar +name+ has been loaded
      #
      # @return [Boolean]
      #   true if ivar +name+ has been loaded
      #
      # @api private
      def attribute_loaded?(name)
        properties[name].loaded?(self)
      end

      # Checks if an attribute has unsaved changes
      #
      # @param [Symbol] name
      #   name of attribute to check for unsaved changes
      #
      # @return [Boolean]
      #   true if attribute has unsaved changes
      #
      # @api semipublic
      def attribute_dirty?(name)
        dirty_attributes.key?(properties[name])
      end

      # Hash of attributes that have unsaved changes
      #
      # @return [Hash]
      #   attributes that have unsaved changes
      #
      # @api semipublic
      def dirty_attributes
        dirty_attributes = {}

        original_attributes.each_key do |property|
          next unless property.respond_to?(:dump)
          dirty_attributes[property] = property.dump(property.get!(self))
        end

        dirty_attributes
      end

      private

      # Gets this instance's Model's properties
      #
      # @return [PropertySet]
      #   List of this Resource's Model's properties
      #
      # @api private
      def properties
        model.properties(repository_name)
      end

      # Fetches all the names of the attributes that have been loaded,
      # even if they are lazy but have been called
      #
      # @return [Array<Property>]
      #   names of attributes that have been loaded
      #
      # @api private
      def fields
        properties.select do |property|
          property.loaded?(self) || (new? && property.default?)
        end
      end
    end # Attributes
  end # Resource
end # DataMapper
