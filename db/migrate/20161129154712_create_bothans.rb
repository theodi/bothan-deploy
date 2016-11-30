class CreateBothans < ActiveRecord::Migration
  def change
    create_table :bothans do |t|
      t.string :app_id
      t.string :token
    end
  end
end
