class AddIuvToCertificati < ActiveRecord::Migration[5.2]
  def change
    add_column :certificati, :iuv, :string
  end
end
