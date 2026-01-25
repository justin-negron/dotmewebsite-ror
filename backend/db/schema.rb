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

ActiveRecord::Schema[7.1].define(version: 2026_01_25_214942) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "blog_posts", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.text "content", null: false
    t.text "excerpt"
    t.boolean "published", default: false
    t.datetime "published_at"
    t.text "tags", default: [], array: true
    t.integer "view_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published", "published_at"], name: "index_blog_posts_on_published_and_published_at"
    t.index ["slug"], name: "index_blog_posts_on_slug", unique: true
    t.index ["tags"], name: "index_blog_posts_on_tags", using: :gin
  end

  create_table "contacts", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "subject"
    t.text "message", null: false
    t.string "status", default: "new"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_contacts_on_created_at"
    t.index ["status"], name: "index_contacts_on_status"
  end

  create_table "experiences", force: :cascade do |t|
    t.string "company", null: false
    t.string "position", null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.text "description"
    t.text "technologies", default: [], array: true
    t.integer "display_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["display_order"], name: "index_experiences_on_display_order"
    t.index ["start_date"], name: "index_experiences_on_start_date"
  end

  create_table "page_views", force: :cascade do |t|
    t.string "path", null: false
    t.text "user_agent"
    t.inet "ip_address"
    t.string "referrer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_page_views_on_created_at"
    t.index ["ip_address"], name: "index_page_views_on_ip_address"
    t.index ["path"], name: "index_page_views_on_path"
  end

  create_table "projects", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.text "tech_stack", default: [], array: true
    t.string "github_url"
    t.string "live_url"
    t.string "image_url"
    t.boolean "featured", default: false
    t.integer "display_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["display_order"], name: "index_projects_on_display_order"
    t.index ["featured"], name: "index_projects_on_featured"
  end

end
