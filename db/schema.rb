# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 9) do

  create_table "favorites", force: :cascade do |t|
    t.integer "user_id"
    t.integer "show_id"
    t.string  "playlist_on_off"
  end

  create_table "playlists", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "episode_1"
    t.string   "episode_2"
    t.string   "episode_3"
    t.string   "episode_4"
    t.string   "episode_5"
    t.string   "episode_6"
    t.string   "episode_7"
    t.string   "episode_8"
    t.string   "episode_9"
    t.string   "episode_10"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "total_runtime"
  end

  create_table "shows", force: :cascade do |t|
    t.integer "api_id"
    t.string  "name"
    t.string  "description"
    t.string  "genre"
    t.string  "network"
    t.string  "start_date"
    t.integer "runtime"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "real_name"
  end

end
