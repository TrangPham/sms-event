class AddFieldsToEvents < ActiveRecord::Migration
  def change
    add_column :events, :talkback, :boolean
    add_column :events, :broadcast, :boolean
    add_column :events, :notify, :boolean
    add_column :events, :confirm, :boolean
  end
end
