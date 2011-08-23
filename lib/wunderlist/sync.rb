require 'curb'
require 'json'
require 'openssl'
require 'uri'

module Wunderlist
  # Strongly based on js/backend/wunderlist.sync.js
  #
  # This is where the 'steps' come from.
  class Sync
    # Debug only, may be removed without warning
    attr_reader :step_1_response
    attr_reader :user_id

    def initialize email, password, options = {}
      @options = Wunderlist::DEFAULTS.merge(options)

      if @options[:app_name] == Wunderlist::DEFAULTS[:app_name]
        STDERR.write "%s:%d: %s\n" % [
          File.expand_path(__FILE__), __LINE__,
          'Please set :app_name and :app_version to non-default values.'
        ]
      end

      @email = email
      if options[:hashed_password]
        @password_md5 = password
      else
        @password_md5 = OpenSSL::Digest.hexdigest('md5', password)
      end
    end

    def sync
      # Sends:
      # - Tasks & lists: already synced, id & version
      # Receives:
      # - New and updated tasks
      # - New and updated lists
      # - TODO: delete_tasks
      # - Current user id
      run_step_1
      # Process step 1 data
      run_step_2
      nil
    end

    def lists
      @lists ||= Array.new
    end

    def tasks
      @tasks ||= Array.new
    end
    attr_writer :lists, :tasks

    protected
    def run_step_1
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

      [:lists, :tasks].each do |table|
        data[:sync_table][table] = web_data_list(
          self.send(table),
          [:online_id, :version]
        ){|it| it.online_id?}
      end
      data[:sync_table][:new_lists] = web_data_list(lists) do |list|
        !(list.deleted? || list.online_id?)
      end

      response = make_call(data)
      @step_1_response = response
    end

    # Just process the data we received in step 1
    def run_step_2
      response = @step_1_response
      @user_id = response['user_id'].to_i
      # FIXME: sync_table (and subs) might not be defined
      # FIXME: need to merge; this incldues updated lists + tasks too
      response['sync_table']['new_lists'].each do |list|
        lists.push Wunderlist::List.from_sync_data(list)
      end
      response['sync_table']['new_tasks'].each do |task|
        tasks.push Wunderlist::Task.from_sync_data(task)
      end
    end

    def make_call data
      post_data = URI.encode_www_form(formify_keys({
        :email    => @email,
        :password => @password_md5,
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
    def web_data_list values, keys = nil, &test
      values.select{|x| test.call(x)}.map do |x|
        if keys
          x.sync_data.select{|k,v| keys.include? k}
        else
          x.sync_data
        end
      end
    end

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
