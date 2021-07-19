Spree::Product.class_eval do
  searchkick word_start: [:name, :brand, :name_and_brand],
    callbacks: false,
    synonyms: -> { ENV["SEARCHKICK_SYNONYMS_FILE"].blank? ? [] : CSV.read(Rails.root + ENV["SEARCHKICK_SYNONYMS_FILE"]) }

  def search_data
    json = {
      id: id,
      name: name,
      description: "#{name} #{brand.try(:name)} #{description} #{meta_keywords} #{meta_description} #{product_properties.map(&:value).join(' ')}",
      keywords: "#{meta_keywords} #{product_properties.map(&:value).join(' ')}",
      active: active?,
      created_at: created_at,
      updated_at: updated_at,
      price: price,
      currency: currency,
      conversions: orders.complete.count,
      taxon_ids: taxon_and_ancestors.map(&:id),
      taxon_names: taxon_and_ancestors.map(&:name),
      orders_count: orders.where('completed_at > ?', 3.months.ago).count,
      subscribable: subscribable,
      list_position: index_list_position,
      member_special: member_special?,
      ingredient_groups: ingredient_groups
    }
    self.classifications.each do |classification|
      json[classification.taxon.sort_key.to_sym] = classification.position
    end

    if brand
      json.merge!(brand: brand.name, name_and_brand: [brand.name, name].join(" "))
    else
      json.merge!(name_and_brand: name)
    end

    Spree::Property.all.each do |prop|
      json.merge!(Hash[prop.filter_name, property(prop.name)])
    end

    Spree::Taxonomy.all.each do |taxonomy|
      json.merge!(Hash[taxonomy.filter_name.downcase, taxon_by_taxonomy(taxonomy.id).map(&:id)])
    end

    json
  end

  def index_list_position
    if self.respond_to? :list_position
      list_position
    else
      0
    end
  end

  def taxon_by_taxonomy(taxonomy_id)
    taxons.joins(:taxonomy).where(spree_taxonomies: { id: taxonomy_id })
  end

  def active?
    available? && (!self.respond_to?(:individual_sale) || individual_sale)
  end

  def self.autocomplete(keywords)
    if keywords
      Spree::Product.search(
        keywords,
        {
          fields: ["name_and_brand"],
          match: :word_start,
          limit: 10,
          load: false,
          boost_by: { orders_count: { factor: 1 } },
          misspellings: { below: 5 },
          where: search_where
        }
      ).map { |p| { id: p.id, value: p.name, brand: p.brand, type: 'item' } }.uniq
    else
      Spree::Product.search(
        '*',
        fields: ["name_and_brand"],
        where: search_where,
        load: false,
        limit: 5000
      ).map { |p| { id: p.id, value: p.name, brand: p.brand } }
    end
  end

  def self.search_where
    {
      active: true,
      price: { not: nil }
    }
  end
end
