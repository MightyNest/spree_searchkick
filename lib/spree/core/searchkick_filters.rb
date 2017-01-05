module Spree
  module Core
    module SearchkickFilters
      def self.applicable_filters(aggregations)
        es_filters = []
        Spree::Taxonomy.filterable.each do |taxonomy|
          es_filters << self.process_filter(taxonomy.filter_name, :taxon, aggregations[taxonomy.filter_name])
        end

        Spree::Property.filterable.each do |property|
          es_filters << self.process_filter(property.filter_name, :property, aggregations[property.filter_name])
        end

        es_filters << self.process_filter('brand', :brand, aggregations['brand'])
        if aggregations.has_key? 'price'
          es_filters << self.process_filter('price', :price, aggregations['price'])
        end
        es_filters.uniq
      end

      def self.process_filter(name, type, filter)
        options = []
        case type
        when :price
          filter["buckets"].each do |bucket|
            label =
              if bucket["from"] && bucket["to"]
                "$#{bucket['from']} - $#{bucket['to']}"
              elsif bucket["from"]
                "$#{bucket['from']} and up"
              elsif bucket["to"]
                "Under $#{bucket['to']}"
              end

            options << { label: label, value: bucket["key"], count: bucket['doc_count']}
          end
        # when :price
        #   min = filter["buckets"].min {|a,b| a["key"] <=> b["key"] }
        #   max = filter["buckets"].max {|a,b| a["key"] <=> b["key"] }
        #   if min && max
        #     options = {min: min["key"].to_i, max: max["key"].to_i, step: 100}
        #   else
        #     options = {}
        #   end
        when :taxon
          ids = filter["buckets"].map{|h| h["key"]}
          id_counts = Hash[filter["buckets"].map { |h| [h["key"], h["doc_count"]] }]
          taxons = Spree::Taxon.where(id: ids).order(name: :asc)
          taxons.each { |t|
            options << {label: t.name, value: t.id, count: id_counts[t.id] }}
        when :property, :brand
          filter["buckets"].each do |filter_val|
            t = filter_val["key"]
            count = filter_val["doc_count"]
            options << {label: t, value: t, count: count }
          end
        end

        {
          name: name,
          type: type,
          options: options
        }
      end

      def self.aggregation_term(aggregation)
        aggregation["buckets"].sort_by { |hsh| hsh["key"] }
      end
    end
  end
end
