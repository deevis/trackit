# == Schema Information
#
# Table name: tracked_sites
#
#  id                                  :bigint           not null, primary key
#  name                                :string(255)
#  url                                 :string(255)
#  category                            :string(255)
#  sub_category                        :string(255)
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  type                                :string(64)
#  current_price                       :decimal(10, 2)
#  current_price_date                  :datetime
#  lowest_price                        :decimal(10, 2)
#  lowest_price_date                   :datetime
#  lowest_price_tracked_site_datum_id  :bigint
#  highest_price                       :decimal(10, 2)
#  highest_price_date                  :datetime
#  highest_price_tracked_site_datum_id :bigint
#  unavailable                         :boolean          default(FALSE)
#  tracked_site_parent_id              :bigint
#  variant_definition                  :text(4294967295)
#  tracked_site_product_index_id       :bigint
#

require 'nokogiri'
require 'open-uri'

class TrackedSite < ApplicationRecord

  # child variants
  belongs_to :tracked_site_parent, optional: true, class_name: "TrackedSite"
  serialize :variant_definition, JSON

  # has_many :child_variants, class_name: "TrackedSite", inverse_of: :tracked_site_parent

  has_many :_actual_tracked_site_data, dependent: :destroy, class_name: "TrackedSiteDatum"
  has_one_attached :image

  belongs_to :lowest_price_tracked_site_datum, class_name: "TrackedSiteDatum", optional: true
  belongs_to :highest_price_tracked_site_datum, class_name: "TrackedSiteDatum", optional: true

  belongs_to :tracked_site_product_index, optional: true
  
  after_create :do_initial_scrape
  
  after_commit :raise_pricing_events, on: :update

  # default_scope ->() { where(unavailable: nil) }

  scope :unavailable, ->() { where(unavailable: true) }
  scope :available, ->() { where(unavailable: nil) }

  scope :best_price_ever, ->(){ where("current_price = lowest_price")
                                .where("current_price < highest_price")}



  def is_best_price_ever?
    self.current_price == self.lowest_price && self.current_price < self.highest_price
  end
  
  def self.display_name; "The Name for display on webpage"; end

  def display_name
    if is_child_variant?
      "#{name} - #{variant_definition}"
    elsif get_default_variant.present?
      "#{name} - #{get_default_variant}"
    else
      name
    end
  end

  def log_name; "#{self.class.to_s}[#{self.id}]"; end
  
  def get_pricing_unit; "$"; end
  
  def get_default_variant; nil; end
  def get_pricing_variants; []; end

  def ensure_valid_variant!(variant)
    variant = JSON.parse(variant) if variant.is_a?(String)
    found = get_pricing_variants.detect{|v| v == variant}
    raise "#{variant} is not a valid variant for #{self.class}" if !found
    found
  end


  def get_price_for(tsd, variant=variant_definition)
    tsd.data['price']
  end

  # no explicit link like lowest/highest...
  def current_price_tracked_site_datum
    tracked_site_data.last
  end

  def get_current_price(variant=variant_definition)
    get_price_for(current_price_tracked_site_datum, variant)
  end

  def tracked_site_data
    if is_child_variant?
      # use the parent's data
      tracked_site_parent._actual_tracked_site_data
    else
      _actual_tracked_site_data
    end
  end
  
  def is_child_variant?
    return true if tracked_site_parent_id.present?
  end

  def create_child_variant(variant)
    raise "Cannot nest child variants - call on the parent please" if is_child_variant?
    raise "No pricing variants defined" if get_pricing_variants.blank?
    valid_variant = ensure_valid_variant!(variant)
    # 1 - make sure the variant is valid
    tsd = tracked_site_data.last
    variant_price = tsd.get_price(valid_variant)
    raise "Could not get variant price for #{variant}" if variant_price == -1
    excluded = %w[id url current_price current_price_date 
        lowest_price lowest_price_date lowest_price_tracked_site_datum_id
        highest_price highest_price_date highest_price_tracked_site_datum_id]

    attrs = self.attributes.clone
    child = TrackedSite.new(attrs.except(*excluded))
    child.tracked_site_parent = self
    child.variant_definition = valid_variant
    child.save!
    # set child pricing
    child.tracked_site_data.each{|tsd| child.update_stats(tsd)}
    child
  end

  def child_variants
    TrackedSite.where(tracked_site_parent_id: self.id)
  end

  # build_price_journey returns price changes and dates along with deltas
   # [
   # {:price=>863800, :date=>Sun, 31 Jul 2022, :delta=>-3200},
   # {:price=>859600, :date=>Tue, 02 Aug 2022, :delta=>-4200},
   # {:price=>854800, :date=>Sat, 06 Aug 2022, :delta=>-4800},
   # {:price=>814700, :date=>Sun, 04 Sep 2022, :delta=>-40100},
   # {:price=>810500, :date=>Fri, 09 Sep 2022, :delta=>-4200},
   # {:price=>808000, :date=>Thu, 15 Sep 2022, :delta=>-2500}
   # ]
  def build_price_journey(limit: 30, for_specific_tsd: nil)
    puts "TrackedSite[#{self.id}].build_price_journey(limit: #{limit}, for_specific_tsd: #{for_specific_tsd&.id})"
    items = []
    last_price = nil
    scope = if for_specific_tsd.present?
      # find info for a single tsd - include only the previous tsd and this one
      for_specific_tsd.get_previous(5).to_a.reverse + [for_specific_tsd]
    else
      tracked_site_data.last(limit+10)
    end

    scope.each do |tsd|
      price = tsd.get_price(self.variant_definition)
      if price != last_price
        # puts "#{last_price}  #{price}  #{tsd.start_time}"
        item = { tsd_id: tsd.id, price: price, date: tsd.start_time}
        item[:delta] = price - last_price if last_price
        items << item
      end
      last_price = price
    end
    for_specific_tsd ? [items.last] : items.reverse[0..(limit-1)]
  end

  def raise_pricing_events
    new_val = ->(k) { previous_changes[k][1] rescue nil}
    old_val = ->(k) { previous_changes[k][0] rescue nil}

    new_value_is = ->(attribute_name, operation = ">") do
      v1, v2 = previous_changes[attribute_name]
      if v1 && v2
        v2.send(operation, v1)
      else
        false
      end
    rescue Exception => e
      puts ""
    end
    # previous changes is a hash of arrays as such:
      # ap previous_changes
      # {
      #       "updated_at" => [
      #         [0] Sat, 10 Sep 2022 22:06:43.000000000 UTC +00:00,
      #         [1] Sat, 10 Sep 2022 22:07:10.000000000 UTC +00:00
      #     ],
      #     "lowest_price" => [
      #         [0] 15.0,   # old_value
      #         [1] 0.0     # new_value
      #     ]
      # }    
    # EVENTS - raise them, log them, run rules based on them
    # 
    # SaleStarted
    # SaleFinished
    #
    # CurrentPriceIncreased?
    if new_val.("current_price") && old_val.("current_price")
      ap previous_changes
      if new_val.("current_price") > old_val.("current_price")
        raise_event("CurrentPriceIncreased", self)
        # LowestEverPriceFinished?
        if old_val.("current_price") == self.lowest_price
          raise_event("LowestEverPriceFinished", self)
        end
      end
      # CurrentPriceDecreased?
      if new_val.("current_price") < old_val.("current_price")
        raise_event("CurrentPriceDecreased", self)
      end
      # 
      # LowestEverPriceStarted?
      if new_val.("lowest_price") < old_val.("lowest_price") || new_val.("current_price") == self.lowest_price
        raise_event("LowestEverPriceStarted", self)
      end
    end
  rescue => e
    # Rails.logger.error e.backtrace.join("\n")
    Rails.logger.error "Not raising events for #{self.log_name}: #{e.message}"
  end

  def raise_event(event_name, instance)
    klass = instance.class.to_s
    id = instance.id
    puts "#{event_name} triggered on #{klass}[#{id}]"
  end

  def self.scrape_latest
    b4 = TrackedSiteDatum.count
    skipped, errors = 0, 0
    error_ids = []
    TrackedSite.available.find_each do |ts|
      next if ts.is_child_variant?
      begin
        result = ts.scrape_latest
        skipped += 1 if result.nil?
      rescue => e
        errors += 1
        error_ids << ts.id
      end
    end
    after = TrackedSiteDatum.count
    sites_scraped = TrackedSite.count - skipped
    puts "Updated #{sites_scraped} sites - #{after - b4} had new data - #{errors} errors encountered".yellow
    puts "TrackedSite error ids: #{error_ids}".red
  end

  def get_data_html(tracked_site_datum)
    "#{tracked_site_datum.start_time.strftime("%m/%d/%Y")} : #{tracked_site_datum.data.class}"
  end

  def scrape_latest(force = false)
    if tracked_site_data.blank?
      Rails.logger.warn "Not performing TrackedSite[#{self.id}].scrape_latest as no tracked_site_data have been populated"
      return nil
    end
    data = scrape_html
    track_data(data) if data
    if child_variants.present?
      child_variants.each do |cv|
        cv.update_stats( self.tracked_site_data.last )
      end
    end
    data
  rescue => e
    Rails.logger.error "Error scraping TrackedSite[#{self.id}][#{self.name}] - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  # Will scrape the HTML from either the #url or the provided filepath ("aaa_gas_prices.html")
  def scrape_html(filepath=nil)
    if filepath.present?
      doc = Nokogiri::HTML(File.readlines(filepath).join("\n"))
      source_location = filepath
    else
      doc = Nokogiri::HTML(URI.open(self.url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
      source_location = self.url
    end
    puts "Got #{doc.to_s.length} bytes from #{source_location}".light_magenta.on_light_yellow
    doc
  rescue => e
    Rails.logger.error("Error encountered scraping #{source_location}")
    Rails.logger.error(e.backtrace.join("\n"))
    Rails.logger.error("Error encountered scraping #{source_location}")
    nil
  end


  # probably called from scrape_html...
  def track_data(data)
    raise "track_data called on child variant" if is_child_variant?
    data = data.stringify_keys if data.present? && data.is_a?(Hash)
    last_tracked = _actual_tracked_site_data.last
    if last_tracked.nil? || last_tracked.data != data
      last_tracked = _actual_tracked_site_data.new
      last_tracked.start_time ||= Time.now
      last_tracked.end_time = Time.now
      last_tracked.data = data
      became_unavailable = last_tracked.data.is_a?(Hash) && last_tracked.data['unavailable']
      if !became_unavailable && (last_tracked.get_price.nil? || last_tracked.get_price < 0) 
        raise "Invalid pricing[#{last_tracked.get_price}] - not creating tracked_site_datum force TrackedSite[#{self.id}]"
      end
      last_tracked.save!
      puts "Created new TrackedDatum[#{last_tracked.id}]".light_yellow.on_green
    elsif last_tracked.data == data
      last_tracked.end_time = Time.now
      puts "Updating end_time on existing TrackedDatum[#{last_tracked.id}]".light_blue.on_light_yellow
      last_tracked.save!
    end
    update_stats(last_tracked)
    # Do we need to update_stats of child variants here?!?
    # No - we don't - they are updated at the end of #scrape_latest
    last_tracked
  end

  # Include the last_tracked TrackedSiteDatum into our price summary fields
  def update_stats(last_tracked, auto_save: true)
    price = last_tracked.get_price(self.variant_definition)
    self.current_price = price
    self.current_price_date = last_tracked.end_time
    self.unavailable = last_tracked.data.is_a?(Hash) ? last_tracked.data['unavailable'] : nil
    if price.present?
      if self.lowest_price.nil? || price <= self.lowest_price
        self.lowest_price = price
        self.lowest_price_date = last_tracked.end_time
        self.lowest_price_tracked_site_datum = last_tracked
      end
      if self.highest_price.nil? || price >= self.highest_price
        self.highest_price = price
        self.highest_price_date = last_tracked.end_time
        self.highest_price_tracked_site_datum = last_tracked
      end
    end
    self.save! if auto_save
  end

  # Clear out price summary fields and recompute
  def recompute_stats
    self.current_price = nil
    self.current_price_date = nil
    self.lowest_price = nil
    self.lowest_price_date = nil
    self.lowest_price_tracked_site_datum_id = nil
    self.highest_price = nil
    self.highest_price_date = nil
    self.highest_price_tracked_site_datum_id = nil
    # self.save!   
    self.tracked_site_data.find_each do |tsd|
      update_stats(tsd, auto_save: false)
    end
    self.save!
  end


  def set_image_from_url(url, force=false)
    if url.blank?
      Rails.logger.warn("TrackedSite[#{self.id}] Unable to set image from blank url")
      return
    end
    if self.image.present? && !force
      Rails.logger.info("Not setting TrackedSite[#{self.id}].image as it is already set")
      return
    end
    downloaded_image = URI.parse(url).open # tis a stream...
    if url.index(".jpg")
      self.image.attach(io: downloaded_image  , filename: "thumbnail.jpg")
    elsif url.index(".png")
      self.image.attach(io: downloaded_image  , filename: "thumbnail.png")
    else
      Rails.logger.warn "Unknown image type (we only know jpg and png) implied in url: #{url} - defaulting to jpg"
      self.image.attach(io: downloaded_image  , filename: "thumbnail.jpg")
    end
  end

  def do_initial_scrape
    # variants are not scraped - their parents hold the information
    return true if is_child_variant? 
    d = self.scrape_html
    self.track_data(d)
  end

  # Loop over all tracked_site_data and purge those with invalid pricing
  def cleanup_invalid_tracked_site_data(dry_run: true)
    bad_tsds = _actual_tracked_site_data.find_each.select do |tsd|
      price = tsd.get_price
      price.nil? || price < 0
    end
    if dry_run
      ap bad_tsds
      puts "Identified #{bad_tsds.length} bad tracked_site_data records that would be purged"
    else
      bad_tsds.each do |tsd|
        tsd.purge
      end
      (cvs = child_variants).each do |cv|
        cv.recompute_stats
      end
      puts "Purged #{bad_tsds.length} bad tracked_site_data records"
      puts "Recomputed stats for #{cvs.length} child variants" if cvs.present?
    end
  end

  def destroy
    self.lowest_price_tracked_site_datum_id = nil
    self.highest_price_tracked_site_datum_id = nil
    self.save!
    super
  end
end
