# == Schema Information
#
# Table name: tracked_site_product_indices
#
#  id                 :bigint           not null, primary key
#  tracked_site_class :string(255)
#  product_index_url  :string(255)
#  category           :string(255)
#  sub_category       :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  data               :text(4294967295)
#
class TrackedSiteProductIndex < ApplicationRecord
    validates :tracked_site_class, presence: true
    validates :product_index_url, presence: true
    validates :category, presence: true
    validates :sub_category, presence: true

    validate :tracked_site_class_exists

    has_many :tracked_sites, dependent: :destroy

    serialize :data, JSON

    def import_products
        # get the product urls
        product_urls = get_product_urls
        Rails.logger.info "Got #{product_urls.length} product urls"
        product_urls.each do |url|
            Rails.logger.info "Product URL: #{url}"
        end
        stats = { created: 0, existing: 0, errors: 0, error_messages: []}
        # create a TrackedSiteProduct for each url
        product_urls.each do |url|
            begin
                # check if a TrackedSite exists for this url
                if (existing = TrackedSite.find_by(url: url)).nil?
                    # create a TrackedSite for this url
                    Rails.logger.info "Creating TrackedSite for #{url}"
                    new_tracked_site = get_tracked_site_class.create(url: url, category: category, sub_category: sub_category, tracked_site_product_index: self)
                    new_tracked_site.scrape_html
                    new_tracked_site.save!
                    stats[:created] += 1
                else
                    Rails.logger.info "TrackedSite[#{existing.id}] already exists for #{url}"
                    stats[:existing] += 1
                end 
            rescue => e
                stats[:errors] += 1
                stats[:error_messages] << e.message
                Rails.logger.error "Error creating TrackedSite for #{url}: #{e.message}"
                Rails.logger.error e.backtrace.join("\n")
            end
        end
        Rails.logger.info "Created #{stats[:created]} TrackedSites, #{stats[:existing]} already existed, and #{stats[:errors]} errors"
        Rails.logger.info "Error messages: #{stats[:error_messages].join(", ")}"
        self.data ||= {}
        self.data["import_stats"] = stats
        self.save!
        stats
    end

    def get_product_urls(force: false)
        # get the product urls from the index page
        if data.present? && data.has_key?("product_urls") && !force
            return data["product_urls"]
        end
        product_urls = get_tracked_site_class.scrape_product_urls(product_index_url)
        self.data ||= {}
        self.data["product_urls"] = product_urls
        self.save!
        product_urls
    end
    
    def get_tracked_site_class
        # get the correct subclass of TrackedSite
        Object.const_get(tracked_site_class)
    end

    private
    def tracked_site_class_exists
        get_tracked_site_class
    rescue NameError
        Rails.logger.warn "TrackedSite class #{tracked_site_class} does not exist"
        errors.add(:tracked_site_class, "class does not exist")
    end


end
