# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_09_08_215556) do
  create_table "combined_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_combined_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_combined_users_on_reset_password_token", unique: true
  end

  create_table "password_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_password_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_password_users_on_reset_password_token", unique: true
  end

  create_table "passwordless_confirmable_users", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "remember_created_at"
    t.string "remember_token", limit: 20
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["confirmation_token"], name: "index_passwordless_confirmable_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_passwordless_confirmable_users_on_email", unique: true
  end

  create_table "passwordless_users", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "remember_created_at"
    t.string "remember_token", limit: 20
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index "\"confirmation_token\"", name: "index_passwordless_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_passwordless_users_on_email", unique: true
  end

end
