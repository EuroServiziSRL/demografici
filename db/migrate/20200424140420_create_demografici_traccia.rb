class CreateDemograficiTraccia < ActiveRecord::Migration[5.2]
  def change
    create_table :demografici_traccia do |t|
      t.datetime :obj_created
      t.datetime :obj_modified
      t.integer :utente_id
      t.string :ip
      t.string :pagina
      t.string :parametri
      t.string :id_transazione_app
      t.string :tipologia_servizio
      t.string :tipologia_richiesta

      t.timestamps
    end
  end
end
