
class NewDownloadOnDemand  < ActiveRecord::Migration

  def self.up
    drop_table :downloads
    add_column :repositories, :download, :string
  end

  def self.down
    remove_column :repositories, :download

    create_table :downloads do |t|
      t.string :baseurl
      t.string :metafile
      t.string :mtype
      t.references :architecture
      t.integer :db_project_id
    end
  end

end
