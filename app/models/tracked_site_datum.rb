# == Schema Information
#
# Table name: tracked_site_data
#
#  id              :bigint           not null, primary key
#  start_time      :datetime
#  end_time        :datetime
#  tracked_site_id :bigint
#  data            :text(4294967295)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class TrackedSiteDatum < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  
  belongs_to :tracked_site

  serialize :data, JSON
  
  def get_price(variant=nil)
    tracked_site.get_price_for(self, variant)
  end

  def get_previous(limit=1)
    tracked_site.tracked_site_data.where("start_time < ?", self.start_time)
                                  .order("start_time DESC").limit(limit)
  end

  def previous
    tracked_site.tracked_site_data.where("tracked_site_data.id < ?", self.id).limit(1).first
  end

  def subsequent
    tracked_site.tracked_site_data.where("tracked_site_data.id < ?", self.id).limit(1).first
  end

  # If this TrackedSiteDatum is no longer wanted (bad data, ...?)
  # then remove this one and adjust the previous and subsequent
  # time ranges to be consistent
  def purge
    # check if this is the highest/lowest/current of a TrackedSite datum
    TrackedSiteDatum.transaction do
      if (p = previous)
        p.end_time = self.start_time
        p.save!
      end
      if (s = subsequent)
        s.start_time = self.end_time
        s.save!
      end
      if tracked_site.lowest_price_tracked_site_datum_id == self.id
        TrackedSite.where(lowest_price_tracked_site_datum_id: self.id).update_all(lowest_price_tracked_site_datum_id: nil)
        tracked_site.lowest_price_tracked_site_datum_id = nil
        tracked_site_changed = true
      end
      if tracked_site.highest_price_tracked_site_datum_id == self.id
        TrackedSite.where(highest_price_tracked_site_datum_id: self.id).update_all(highest_price_tracked_site_datum_id: nil)
        tracked_site.highest_price_tracked_site_datum_id = nil
        tracked_site_changed = true
      end

      if tracked_site_changed
        tracked_site.save!
        self.destroy
        tracked_site.recompute_stats
        tracked_site.save!
      else
        self.destroy
      end
    end
  end

  def get_formatted_price(variant=nil)
    p = get_price(variant)
    if p.is_a?(Hash)
      price = p[:price]
    end
    case tracked_site.get_pricing_unit
    when "$"
      return number_to_currency(price)
    when "%"
      return number_to_percentage(price)
    else 
      return price
    end
  end

end
