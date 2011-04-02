module DataMapper
  module Resource
    module RaiseOnSave
      # Return if Resource#save should raise an exception on save failures (per-resource)
      #
      # This delegates to model.raise_on_save_failure by default.
      #
      #   user.raise_on_save_failure  # => false
      #
      # @return [Boolean]
      #   true if a failure in Resource#save should raise an exception
      #
      # @api public
      def raise_on_save_failure
        if defined?(@raise_on_save_failure)
          @raise_on_save_failure
        else
          model.raise_on_save_failure
        end
      end

      # Specify if Resource#save should raise an exception on save failures (per-resource)
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
    end # RaiseOnSave
  end # Resource
end # DataMapper
