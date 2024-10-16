# frozen_string_literal: true

module FortyFacets
  class RangeFilterDefinition < FilterDefinition
    class RangeFilter < Filter
      RANGE_REGEX = /([\d,.]*) - ([\d,.]*)/

      def build_scope
        return proc { |base| base } if empty?

        proc do |base|
          scope = base.joins(definition.joins)
          scope = scope.where("#{definition.qualified_column_name} >= ?", min_value) if min_value.present?
          scope = scope.where("#{definition.qualified_column_name} <= ?", max_value) if max_value.present?
          scope
        end
      end

      def min_value
        min, _max = range_values
        min
      end

      def max_value
        _min, max = range_values
        max
      end

      def absolute_interval
        @abosultes ||=
          without
          .result
          .reorder('')
          .select("min(#{definition.qualified_column_name}) AS min, max(#{definition.qualified_column_name}) as max")
          .order("min(#{definition.qualified_column_name})")
          .first
      end

      def absolute_min
        absolute_interval.min
      end

      def absolute_max
        absolute_interval.max
      end

      private

      def range_values
        date_time_values || date_values || number_values
      end

      def date_time_values
        date_time_regex = Regexp.new(/(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/)
        date_time_regex_range = Regexp.new(/#{date_time_regex} - #{date_time_regex}/)
        value&.match(date_time_regex_range)&.captures
      end

      def date_values
        date_regex = Regexp.new(/(\d{4}-\d{2}-\d{2})/)
        date_regex_range = Regexp.new(/#{date_regex} - #{date_regex}/)
        value&.match(date_regex_range)&.captures
      end

      def number_values
        value&.match(RANGE_REGEX)&.captures
      end
    end

    def build_filter(search_instance, value)
      RangeFilter.new(self, search_instance, value)
    end
  end
end
