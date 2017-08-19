require "rest-client"

require "carrierwave"
require "weixin_authorize/carrierwave/weixin_uploader"

require 'yajl/json_gem'

require "weixin_authorize/config"
require "weixin_authorize/handler"
require "weixin_authorize/api"
require "weixin_authorize/client"

module WeixinAuthorize

  # Storage
  autoload(:Storage,       "weixin_authorize/adapter/storage")
  autoload(:ClientStorage, "weixin_authorize/adapter/client_storage")
  autoload(:RedisStorage,  "weixin_authorize/adapter/redis_storage")

  OK_MSG     = "ok".freeze
  OK_CODE    = 0.freeze
  GRANT_TYPE = "client_credential".freeze
  TIMEOUT = 15

  class << self

    def http_get_without_token(url, headers={}, endpoint="plain")
      get_api_url = endpoint_url(endpoint, url)
      args = { method: :get, url: get_api_url, open_timeout: TIMEOUT, timeout: TIMEOUT}.merge({headers: headers})
      # load_json(RestClient.get(get_api_url, :params => headers))
      load_json( RestClient::Request.execute(args) )
    end

    def http_post_without_token(url, payload={}, headers={}, endpoint="plain")
      post_api_url = endpoint_url(endpoint, url)
      payload = JSON.dump(payload) if endpoint == "plain" # to json if invoke "plain"
      args = { method: :post, url: post_api_url, payload: payload, open_timeout: TIMEOUT, timeout: TIMEOUT}.merge({headers: headers})
      load_json( RestClient::Request.execute(args) )
    end

    # return hash
    def load_json(string)
      result_hash = JSON.parse(string)
      code   = result_hash.delete("errcode")
      en_msg = result_hash.delete("errmsg")
      ResultHandler.new(code, en_msg, result_hash)
    end

    def endpoint_url(endpoint, url)
      send("#{endpoint}_endpoint") + url
    end

    def plain_endpoint
      "https://api.weixin.qq.com/cgi-bin"
    end

    def file_endpoint
      "http://file.api.weixin.qq.com/cgi-bin"
    end

    def mp_endpoint(url)
      "https://mp.weixin.qq.com/cgi-bin#{url}"
    end

  end

end
