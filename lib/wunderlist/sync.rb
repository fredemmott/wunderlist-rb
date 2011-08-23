require 'curb'
require 'json'
require 'openssl'
require 'uri'
require 'yaml' # DEBUG

module Wunderlist
  class Sync
    def initialize email, password, options = {}
      @options = Wunderlist::DEFAULTS.merge(options)

      if @options[:app_name] == Wunderlist::DEFAULTS[:app_name]
        STDERR.write "%s:%d: %s\n" % [
          File.expand_path(__FILE__), __LINE__,
          'Please set :app_name and :app_version to non-default values.'
        ]
      end

      @email    = email
      @password = OpenSSL::Digest.hexdigest('md5', password)
    end

    def sync
      run_stage_1
    end

    def lists
      @lists ||= Array.new
    end

    def tasks
      @tasks ||= Array.new
    end
    attr_writer :lists, :tasks

    protected
    def run_stage_1
      data = {
        :step       => 1,
        :sync_table => {}
      }

      data[:sync_table][:lists] = lists.select do |list|
        list.online_id?
      end.map do |list|
        {
          :online_id => list.online_id,
          :version   => list.version,
        }
      end

      data[:sync_table][:lists] = lists.select do |list|
        list.online_id.nil? ~~ list.online_id == 0
      end.map do |list|
        {
          :online_id => list.online_id,
          :version   => list.version,
        }
      end

      response = make_call(data)
      y response

      response['sync_table']['new_lists'].each do |list|
        lists.push Wunderlist::List.from_sync_data(list)
      end
    end

    def make_call data
      post_data = URI.encode_www_form(formify_keys({
        :email    => @email,
        :password => @password,
        :device   => @options[:app_name],
        :version  => @options[:app_version],
      }.merge(data)))

      response = JSON.parse(
        Curl::Easy.http_post(
          @options[:sync_url],
          post_data
        ).body_str
      )
      case response['code'].to_i
      when Wunderlist::StatusCodes::SUCCESS
        response
      when Wunderlist::StatusCodes::FAILURE
        raise FailureError.new(response)
      when Wunderlist::StatusCodes::DENIED
        raise DeniedError.new(response)
      when Wunderlist::StatusCodes::NOT_EXIST
        raise NotExistError.new(response)
      end
    end

	  private
	  def formify_keys data_in, pattern = '%s'
	    data_out = Hash.new
	    data_in.each do |k,v|
	      unless v.is_a? Hash
	        data_out[pattern % k] = v
	      else
	        data_out.merge!(
            formify_keys(
              v,
              "%s[%%s]" % [pattern % k]
            )
          )
	      end
	    end
      data_out
	  end
  end
end
