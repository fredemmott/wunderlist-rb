module Wunderlist
  DEFAULTS = {
    :sync_url    => 'https://sync.wunderlist.net/1.2.0',
    :app_name    => 'wunderlist-rb',
    :app_version => '0.0.1',
  }

  # *Not* returned as HTTP status codes.
  #
  # These are returned as a 'code' attribute in a JSON object returned by
  # the server.
  module StatusCodes
    SUCCESS   = 300
    FAILURE   = 301
    DENIED    = 302
    NOT_EXIST = 303
  end

  class Error < RuntimeError; end
  class FailureError < Wunderlist::Error; end
  class DeniedError < Wunderlist::Error; end
  class NotExistError < Wunderlist::Error; end
end

require 'wunderlist/list'
require 'wunderlist/task'
require 'wunderlist/sync'
