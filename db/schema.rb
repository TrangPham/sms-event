# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130602000149) do

  create_table "event_users", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "event_id"
    t.integer  "user_id"
  end

  create_table "events", :force => true do |t|
    t.integer  "event_id"
    t.string   "name"
    t.text     "description"
    t.integer  "organizer_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.boolean  "talkback"
    t.boolean  "broadcast"
    t.boolean  "notify"
    t.boolean  "confirm"
  end

  create_table "events_users", :force => true do |t|
    t.integer "event_id"
    t.integer "user_id"
  end

  create_table "users", :force => true do |t|
    t.string   "phone"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
