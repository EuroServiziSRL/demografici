class ChangeCertificatiColumns2 < ActiveRecord::Migration[5.2]
  def change
    remove_column :certificatis, :codice_certificato, :string
    remove_column :certificatis, :diritti_segreteria, :boolean
    change_column :certificatis, :bollo, :decimal
    add_column :certificatis, :diritti_importo, :decimal
    add_column :certificatis, :codici_certificato, :string  
  end
end
