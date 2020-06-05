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

ActiveRecord::Schema.define(version: 2020_06_05_092534) do

  create_table "certificatis", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "tenant"
    t.string "codice_fiscale"
    t.decimal "bollo", precision: 4, scale: 2
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
    t.decimal "diritti_importo", precision: 4, scale: 2
    t.string "codici_certificato"
    t.string "descrizione_errore"
  end

  create_table "comunis", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.date "dataistituzione"
    t.date "datacessazione"
    t.integer "codistat"
    t.string "codcatastale"
    t.string "denominazione_it"
    t.string "denomtraslitterata"
    t.string "altradenominazione"
    t.string "altradenomtraslitterata"
    t.integer "idprovincia"
    t.integer "idregione"
    t.string "idprefettura"
    t.string "stato"
    t.string "siglaprovincia"
    t.string "fonte"
    t.date "dataultimoagg"
    t.integer "cod_denom"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "demografici_traccia", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  create_table "esenzione_bollos", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "descrizione"
    t.boolean "esenzione_diritto_di_segreteria"
    t.integer "ordinamento"
    t.date "datainiziovalidita"
    t.date "datafinevalidita"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "relazioni_parentelas", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "id_relazione", null: false
    t.string "descrizione"
    t.integer "ordinamento"
    t.date "datainiziovalidita"
    t.date "datafinevalidita"
    t.string "note"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "stati_esteris", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "denominazione"
    t.string "denominazioneistat"
    t.string "denominazioneistat_en"
    t.date "datainiziovalidita"
    t.date "datafinevalidita"
    t.string "codiso3166_1_alpha3"
    t.integer "codmae"
    t.integer "codmin"
    t.string "codat"
    t.string "codistat"
    t.boolean "cittadinanza"
    t.boolean "nascita"
    t.boolean "residenza"
    t.string "fonte"
    t.string "tipo"
    t.string "codisosovrano"
    t.date "dataultimoagg"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "tipo_certificatos", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "descrizione"
    t.integer "ordinamento"
    t.date "datainiziovalidita"
    t.date "datafinevalidita"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

end
