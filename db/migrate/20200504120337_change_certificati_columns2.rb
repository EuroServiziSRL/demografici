class ChangeCertificatiColumns2 < ActiveRecord::Migration[5.2]
  def change
    remove_column :certificati, :codice_certificato, :string
    remove_column :certificati, :diritti_segreteria, :boolean
    change_column :certificati, :bollo, :decimal
    add_column :certificati, :diritti_importo, :decimal
    add_column :certificati, :codici_certificato, :string  
  end
end
