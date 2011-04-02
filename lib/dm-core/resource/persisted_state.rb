module DataMapper
  module Resource
    module PersistedState
      # Checks if this Resource instance is new
      #
      # @return [Boolean]
      #   true if the resource is new and not saved
      #
      # @api public
      def new?
        persisted_state.kind_of?(State::Transient)
      end

      # Checks if this Resource instance is saved
      #
      # @return [Boolean]
      #   true if the resource has been saved
      #
      # @api public
      def saved?
        persisted_state.kind_of?(State::Persisted)
      end

      # Checks if this Resource instance is destroyed
      #
      # @return [Boolean]
      #   true if the resource has been destroyed
      #
      # @api public
      def destroyed?
        readonly? && !key.nil?
      end

      # Checks if the resource has no changes to save
      #
      # @return [Boolean]
      #   true if the resource may not be persisted
      #
      # @api public
      def clean?
        persisted_state.kind_of?(State::Clean) || persisted_state.kind_of?(State::Immutable)
      end

      # Checks if the resource has unsaved changes
      #
      # @return [Boolean]
      #  true if resource may be persisted
      #
      # @api public
      def dirty?
        run_once(true) do
          dirty_self? || dirty_parents? || dirty_children?
        end
      end

      # Checks if this Resource instance is readonly
      #
      # @return [Boolean]
      #   true if the resource cannot be persisted
      #
      # @api public
      def readonly?
        persisted_state.kind_of?(State::Immutable)
      end

      # Get the persisted state for the resource
      #
      # @return [Resource::State]
      #   the current persisted state for the resource
      #
      # @api private
      def persisted_state
        @_state ||= Resource::State::Transient.new(self)
      end

      # Set the persisted state for the resource
      #
      # @param [Resource::State]
      #   the new persisted state for the resource
      #
      # @return [undefined]
      #
      # @api private
      def persisted_state=(state)
        @_state = state
      end

      # Test if the persisted state is set
      #
      # @return [Boolean]
      #   true if the persisted state is set
      #
      # @api private
      def persisted_state?
        defined?(@_state) ? true : false
      end

      private

      # Commit the persisted state
      #
      # @return [undefined]
      #
      # @api private
      def _persist
        self.persisted_state = persisted_state.commit
      end
    end # PersistedState
  end # Resource
end # DataMapper
