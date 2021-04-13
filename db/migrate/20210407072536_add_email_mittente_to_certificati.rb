class AddEmailMittenteToCertificati < ActiveRecord::Migration[5.2]
  def change
    add_column :certificati, :email_mittente, :string
  end
end
