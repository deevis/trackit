# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2024_04_06_074204) do
  create_table "active_storage_attachments", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb3", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "forecasts", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "station_id"
    t.datetime "time", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "temp_min"
    t.integer "temp_max"
    t.integer "temp_diff"
    t.integer "temp_diff_hours"
    t.float "temp_diff_per_hour"
    t.integer "wind_min"
    t.integer "wind_max"
    t.integer "wind_diff"
    t.integer "wind_diff_hours"
    t.float "wind_diff_per_hour"
    t.datetime "end_time"
    t.integer "current_temp"
    t.integer "current_wind"
    t.index ["station_id", "end_time"], name: "index_forecasts_on_station_id_and_end_time"
    t.index ["station_id", "time"], name: "index_forecasts_on_station_id_and_time"
    t.index ["station_id"], name: "index_forecasts_on_station_id"
    t.index ["temp_diff"], name: "index_forecasts_on_temp_diff"
    t.index ["wind_diff"], name: "index_forecasts_on_wind_diff"
  end

  create_table "predictions", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "forecast_id"
    t.bigint "station_id"
    t.datetime "start_time", precision: nil
    t.datetime "end_time", precision: nil
    t.integer "temperature"
    t.string "temperature_unit", limit: 1
    t.integer "wind_speed"
    t.string "wind_unit", limit: 4
    t.string "wind_direction", limit: 4
    t.string "short_forecast"
    t.string "icon", limit: 30
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["forecast_id"], name: "index_predictions_on_forecast_id"
    t.index ["station_id", "start_time"], name: "index_predictions_on_station_id_and_start_time"
    t.index ["station_id"], name: "index_predictions_on_station_id"
  end

  create_table "stations", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.string "city"
    t.string "state"
    t.text "data", size: :long, collation: "utf8mb4_bin"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "last_forecast_time", precision: nil
    t.bigint "current_forecast_id"
    t.index ["current_forecast_id"], name: "index_stations_on_current_forecast_id"
    t.check_constraint "json_valid(`data`)", name: "data"
  end

  create_table "tracked_site_data", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "start_time", precision: nil
    t.datetime "end_time", precision: nil
    t.bigint "tracked_site_id"
    t.text "data", size: :long, collation: "utf8mb4_bin"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["tracked_site_id"], name: "index_tracked_site_data_on_tracked_site_id"
    t.check_constraint "json_valid(`data`)", name: "data"
  end

  create_table "tracked_site_product_indices", charset: "utf8mb4", force: :cascade do |t|
    t.string "tracked_site_class"
    t.string "product_index_url"
    t.string "category"
    t.string "sub_category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "data", size: :long, collation: "utf8mb4_bin"
    t.check_constraint "json_valid(`data`)", name: "data"
  end

  create_table "tracked_sites", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.string "category"
    t.string "sub_category"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "type", limit: 64
    t.decimal "current_price", precision: 10, scale: 2
    t.datetime "current_price_date"
    t.decimal "lowest_price", precision: 10, scale: 2
    t.datetime "lowest_price_date"
    t.bigint "lowest_price_tracked_site_datum_id"
    t.decimal "highest_price", precision: 10, scale: 2
    t.datetime "highest_price_date"
    t.bigint "highest_price_tracked_site_datum_id"
    t.boolean "unavailable", default: false
    t.bigint "tracked_site_parent_id"
    t.text "variant_definition", size: :long, collation: "utf8mb4_bin"
    t.bigint "tracked_site_product_index_id"
    t.index ["highest_price_tracked_site_datum_id"], name: "fk_rails_e361b1f9c4"
    t.index ["lowest_price_tracked_site_datum_id"], name: "fk_rails_4fe7dc7b66"
    t.index ["tracked_site_parent_id"], name: "fk_rails_cb9dc3b646"
    t.index ["tracked_site_product_index_id"], name: "index_tracked_sites_on_tracked_site_product_index_id"
    t.index ["url"], name: "index_tracked_sites_on_url", unique: true
    t.check_constraint "json_valid(`variant_definition`)", name: "variant_definition"
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "forecasts", "stations"
  add_foreign_key "predictions", "forecasts"
  add_foreign_key "predictions", "stations"
  add_foreign_key "tracked_site_data", "tracked_sites"
  add_foreign_key "tracked_sites", "tracked_site_data", column: "highest_price_tracked_site_datum_id"
  add_foreign_key "tracked_sites", "tracked_site_data", column: "lowest_price_tracked_site_datum_id"
  add_foreign_key "tracked_sites", "tracked_site_product_indices"
  add_foreign_key "tracked_sites", "tracked_sites", column: "tracked_site_parent_id"
end
