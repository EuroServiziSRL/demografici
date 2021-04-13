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

ActiveRecord::Schema.define(version: 2021_04_07_072536) do

  create_table "certificati", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "tenant"
    t.string "codice_fiscale"
    t.decimal "bollo", precision: 10
    t.string "uso"
    t.string "richiedente_cf"
    t.string "richiesta"
    t.string "stato"
    t.datetime "data_inserimento"
    t.datetime "data_prenotazione"
    t.string "email"
    t.integer "id_utente"
    t.string "documento"
    t.string "nome_certificato"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bollo_esenzione"
    t.string "richiedente_cognome"
    t.string "richiedente_nome"
    t.date "richiedente_data_nascita"
    t.string "richiedente_doc_riconoscimento"
    t.date "richiedente_doc_data"
    t.decimal "diritti_importo", precision: 10
    t.string "codici_certificato"
    t.datetime "data_download"
    t.string "email_mittente"
  end

  create_table "demografici_traccia", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "obj_created"
    t.datetime "obj_modified"
    t.integer "utente_id"
    t.string "ip"
    t.string "pagina"
    t.string "parametri"
    t.string "id_transazione_app"
    t.string "tipologia_servizio"
    t.string "tipologia_richiesta"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
