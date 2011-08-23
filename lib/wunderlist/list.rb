module Wunderlist
  class List
    ATTRIBUTES = [
      :deleted,
      :inbox,
      :name,
      :online_id,
      :position,
      :shared,
      :user_id,
      :version,
    ]
    attr_accessor *ATTRIBUTES
    alias :deleted? :deleted
    alias :inbox?   :inbox
    alias :shared?  :shared
    def online_id?
      online_id && online_id != 0
    end

    def initialize data = {}
      data.each do |k,v|
        self.send("%s=" % k, v) if ATTRIBUTES.include? k
      end
      self.version ||= 0
    end

    def hash
      data = Hash.new
      ATTRIBUTES.each do |key|
        data[key] = self.send(key)
      end
      data
    end

    def sync_data
      data = self.hash
      web_data = Hash.new
      data.each do |k,v|
        case k
        when :deleted, :inbox, :shared
          web_data[k] = v ? 1 : 0
        else
          web_data[k] = v
        end
      end
      web_data
    end

    def self.from_sync_data web_data
      data = Hash.new
      web_data.each do |k,v|
        case k.to_s
        when 'deleted', 'inbox', 'shared'
          data[k.to_sym] = v != '0'
        when 'name'
          data[:name] = v.to_s
        else
          data[k.to_sym] = v.to_i
        end
      end
      Wunderlist::List.new(data)
    end

  end
end
