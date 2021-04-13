class ChangeCertificatiColumns < ActiveRecord::Migration[5.2]
  def change    
    add_column :certificati, :bollo_esenzione, :integer
    add_column :certificati, :richiedente_cognome, :string
    add_column :certificati, :richiedente_nome, :string
    add_column :certificati, :richiedente_data_nascita, :date
    add_column :certificati, :richiedente_doc_riconoscimento, :string
    add_column :certificati, :richiedente_doc_data, :date  
  end
end
