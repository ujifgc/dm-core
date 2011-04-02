module DataMapper
  module Resource
    module Hooks

      protected

      # Method for hooking callbacks before resource saving
      #
      # @return [undefined]
      #
      # @api private
      def before_save_hook
        execute_hooks_for(:before, :save)
      end

      # Method for hooking callbacks after resource saving
      #
      # @return [undefined]
      #
      # @api private
      def after_save_hook
        execute_hooks_for(:after, :save)
      end

      # Method for hooking callbacks before resource creation
      #
      # @return [undefined]
      #
      # @api private
      def before_create_hook
        execute_hooks_for(:before, :create)
      end

      # Method for hooking callbacks after resource creation
      #
      # @return [undefined]
      #
      # @api private
      def after_create_hook
        execute_hooks_for(:after, :create)
      end

      # Method for hooking callbacks before resource updating
      #
      # @return [undefined]
      #
      # @api private
      def before_update_hook
        execute_hooks_for(:before, :update)
      end

      # Method for hooking callbacks after resource updating
      #
      # @return [undefined]
      #
      # @api private
      def after_update_hook
        execute_hooks_for(:after, :update)
      end

      # Method for hooking callbacks before resource destruction
      #
      # @return [undefined]
      #
      # @api private
      def before_destroy_hook
        execute_hooks_for(:before, :destroy)
      end

      # Method for hooking callbacks after resource destruction
      #
      # @return [undefined]
      #
      # @api private
      def after_destroy_hook
        execute_hooks_for(:after, :destroy)
      end

      private

      # This method executes the hooks before and after resource creation
      #
      # @return [Boolean]
      #
      # @see Resource#_create
      #
      # @api private
      def create_with_hooks
        catch :halt do
          before_save_hook
          before_create_hook
          _persist
          after_create_hook
          after_save_hook
        end
      end

      # This method executes the hooks before and after resource updating
      #
      # @return [Boolean]
      #
      # @see Resource#_update
      #
      # @api private
      def update_with_hooks
        catch :halt do
          before_save_hook
          before_update_hook
          _persist
          after_update_hook
          after_save_hook
        end
      end

      # Execute all the queued up hooks for a given type and name
      #
      # @param [Symbol] type
      #   the type of hook to execute (before or after)
      # @param [Symbol] name
      #   the name of the hook to execute
      #
      # @return [undefined]
      #
      # @api private
      def execute_hooks_for(type, name)
        model.hooks[name][type].each { |hook| hook.call(self) }
      end
    end # Hooks
  end # Resource
end # DataMapper
