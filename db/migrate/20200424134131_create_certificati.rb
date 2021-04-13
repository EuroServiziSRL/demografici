class CreateCertificati < ActiveRecord::Migration[5.2]
  def change
    create_table :certificati do |t|
      t.string :tenant
      t.string :codice_fiscale
      t.string :codice_certificato
      t.boolean :bollo
      t.boolean :diritti_segreteria
      t.string :uso
      t.string :richiedente_cf
      t.string :richiesta
      t.string :stato
      t.datetime :data_inserimento
      t.datetime :data_prenotazione
      t.string :email
      t.integer :id_utente
      t.string :documento
      t.string :nome_certificato

      t.timestamps
    end
  end
end
