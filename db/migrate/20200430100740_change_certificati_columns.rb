class ChangeCertificatiColumns < ActiveRecord::Migration[5.2]
  def change    
    add_column :certificatis, :bollo_esenzione, :integer
    add_column :certificatis, :richiedente_cognome, :string
    add_column :certificatis, :richiedente_nome, :string
    add_column :certificatis, :richiedente_data_nascita, :date
    add_column :certificatis, :richiedente_doc_riconoscimento, :string
    add_column :certificatis, :richiedente_doc_data, :date  
  end
end
