module HistoryElement
# This class represents some kind of event within the build service
# that users (or services) would like to know about
  class Base < ActiveRecord::Base

    belongs_to :user

    self.table_name = 'history_elements'

    class << self
      attr_accessor :description, :raw_type
      attr_accessor :comment, :raw_type
      attr_accessor :created_at, :raw_type
      @object = nil
    end

    def color
      nil
    end
  end

end