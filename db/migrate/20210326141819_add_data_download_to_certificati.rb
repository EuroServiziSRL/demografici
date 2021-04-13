class AddDataDownloadToCertificati < ActiveRecord::Migration[5.2]
  def change
    add_column :certificati, :data_download, :datetime
  end
end
