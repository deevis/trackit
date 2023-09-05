class TrackedSitesController < ApplicationController
  before_action :set_tracked_site, 
    only: [:show, :edit, :update, :destroy, :scrape_latest, :add_child_variant]

  # GET /tracked_sites
  # GET /tracked_sites.json
  def index
    @classes = TrackedSite.descendants.sort_by{|d| d.display_name}
    @class = TrackedSite.descendants.detect{|d| d.display_name == params[:site_source]}
    show_unavailable = params[:show_unavailable] == 'true'
    scope = show_unavailable ? TrackedSite.unavailable : TrackedSite.available
    if @class.present?
      scope = scope.where(type: @class.to_s)
      @categories = scope.where(type: @class.to_s).group(:category).count
      @title = "#{@class.display_name}"
    else
      @categories = []
    end
    @best_buy_lowest_prices = []
    if params[:category].present?
      scope = scope.where(category: params[:category])
      @title = "#{@title} - #{params[:category]}"
    elsif @class == TrackedSites::BestBuy
      @best_buy_lowest_prices = TrackedSites::BestBuy.joins(:lowest_price_tracked_site_datum).best_price_ever.order("tracked_site_data.start_time DESC")
      scope = []
    elsif show_unavailable
      scope = scope.order(current_price_date: :desc)
    elsif @class.blank?
      # show only the products at their best price ever on general index
      scope = scope.best_price_ever
    end
    @tracked_sites = scope
  end

  # GET /tracked_sites/1
  # GET /tracked_sites/1.json
  def show
  end

  def scrape_latest
    start = Time.now
    @tracked_site.scrape_latest
    redirect_to @tracked_site, notice: "#{@tracked_site.name} scraped in #{(Time.now - start).round(2)} seconds"
  end

  def add_child_variant
    variant = params[:variant]
    child_variant = @tracked_site.create_child_variant(variant)
    redirect_to child_variant, notice: "New variant made from #{@tracked_site.display_name}"
  rescue => e
    redirect_back_or_to tracked_site_path(@tracked_site), notice: "Could not create child variant: #{e.message}"
  end

  # GET /tracked_sites/new
  def new
    @tracked_site = TrackedSite.new
  end

  # GET /tracked_sites/1/edit
  def edit
  end

  # POST /tracked_sites
  # POST /tracked_sites.json
  def create
    @tracked_site = TrackedSite.new(tracked_site_params)

    respond_to do |format|
      if @tracked_site.save
        format.html { redirect_to tracked_site_path(@tracked_site), notice: 'Tracked site was successfully created.' }
        format.json { render :show, status: :created, location: tracked_site_path(@tracked_site) }
      else
        format.html { render :new }
        format.json { render json: @tracked_site.errors, status: :unprocessable_entity }
      end
    end
  rescue => e
    redirect_back_or_to tracked_sites_path, notice: "Could not create TrackedSite: #{e.message}"
  end

  # PATCH/PUT /tracked_sites/1
  # PATCH/PUT /tracked_sites/1.json
  def update
    respond_to do |format|
      if @tracked_site.update(tracked_site_params)
        format.html { redirect_to tracked_site_path(@tracked_site), notice: 'Tracked site was successfully updated.' }
        format.json { render :show, status: :ok, location: tracked_site_path(@tracked_site) }
      else
        format.html { render :edit }
        format.json { render json: @tracked_site.errors, status: :unprocessable_entity }
      end
    end
  rescue => e
    redirect_back_or_to tracked_site_path(@tracked_site), notice: "Could not update: #{e.message}"
  end

  # DELETE /tracked_sites/1
  # DELETE /tracked_sites/1.json
  def destroy
    @tracked_site.destroy
    respond_to do |format|
      format.html { redirect_to tracked_sites_url, notice: 'Tracked site was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tracked_site
      @tracked_site = TrackedSite.unscoped.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tracked_site_params
      params.require(:tracked_site).permit(:name, :url, :category, :sub_category, :type)
    end
end
