class TrackedSiteProductIndicesController < ApplicationController
  before_action :set_tracked_site_product_index, only: %i[ show edit update destroy import_products ]

  # GET /tracked_site_product_indices or /tracked_site_product_indices.json
  def index
    @tracked_site_product_indices = TrackedSiteProductIndex.all
  end

  # GET /tracked_site_product_indices/1 or /tracked_site_product_indices/1.json
  def show
  end

  def import_products
    stats = @tracked_site_product_index.import_products
    redirect_to @tracked_site_product_index, notice: stats.to_s
  end

  # GET /tracked_site_product_indices/new
  def new
    @tracked_site_product_index = TrackedSiteProductIndex.new
  end

  # GET /tracked_site_product_indices/1/edit
  def edit
  end

  # POST /tracked_site_product_indices or /tracked_site_product_indices.json
  def create
    @tracked_site_product_index = TrackedSiteProductIndex.new(tracked_site_product_index_params)

    respond_to do |format|
      if @tracked_site_product_index.save
        format.html { redirect_to tracked_site_product_index_url(@tracked_site_product_index), notice: "Tracked site product index was successfully created." }
        format.json { render :show, status: :created, location: @tracked_site_product_index }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tracked_site_product_index.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tracked_site_product_indices/1 or /tracked_site_product_indices/1.json
  def update
    respond_to do |format|
      if @tracked_site_product_index.update(tracked_site_product_index_params)
        format.html { redirect_to tracked_site_product_index_url(@tracked_site_product_index), notice: "Tracked site product index was successfully updated." }
        format.json { render :show, status: :ok, location: @tracked_site_product_index }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tracked_site_product_index.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tracked_site_product_indices/1 or /tracked_site_product_indices/1.json
  def destroy
    @tracked_site_product_index.destroy

    respond_to do |format|
      format.html { redirect_to tracked_site_product_indices_url, notice: "Tracked site product index was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tracked_site_product_index
      @tracked_site_product_index = TrackedSiteProductIndex.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tracked_site_product_index_params
      params.require(:tracked_site_product_index).permit(:tracked_site_class, :product_index_url, :category, :sub_category)
    end
end
