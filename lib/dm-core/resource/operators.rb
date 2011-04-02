module DataMapper
  module Resource
    module Operators
      # Compares another Resource for equality
      #
      # Resource is equal to +other+ if they are the same object
      # (identical object_id) or if they are both of the *same model* and
      # all of their attributes are equivalent
      #
      # @param [Resource] other
      #   the other Resource to compare with
      #
      # @return [Boolean]
      #   true if they are equal, false if not
      #
      # @api public
      def eql?(other)
        return true if equal?(other)
        instance_of?(other.class) && cmp?(other, :eql?)
      end

      # Compares another Resource for equivalency
      #
      # Resource is equivalent to +other+ if they are the same object
      # (identical object_id) or all of their attribute are equivalent
      #
      # @param [Resource] other
      #   the other Resource to compare with
      #
      # @return [Boolean]
      #   true if they are equivalent, false if not
      #
      # @api public
      def ==(other)
        return true if equal?(other)
        return false unless other.kind_of?(Resource) && model.base_model.equal?(other.model.base_model)
        cmp?(other, :==)
      end

      # Compares two Resources to allow them to be sorted
      #
      # @param [Resource] other
      #   The other Resource to compare with
      #
      # @return [Integer]
      #   Return 0 if Resources should be sorted as the same, -1 if the
      #   other Resource should be after self, and 1 if the other Resource
      #   should be before self
      #
      # @api public
      def <=>(other)
        model = self.model
        unless other.kind_of?(model.base_model)
          raise ArgumentError, "Cannot compare a #{other.class} instance with a #{model} instance"
        end
        model.default_order(repository_name).each do |direction|
          cmp = direction.get(self) <=> direction.get(other)
          return cmp if cmp.nonzero?
        end
        0
      end
    end # Operators
  end # Resource
end # DataMapper
