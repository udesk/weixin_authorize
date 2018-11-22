# encoding: utf-8
require "redis"
require 'digest/md5'
module WeixinAuthorize

  class Client
    include Api::User
    include Api::Menu
    include Api::Custom
    include Api::Groups
    include Api::Qrcode
    include Api::Media

    attr_accessor :app_id, :app_secret, :expired_at # Time.now + expires_in
    attr_accessor :access_token, :redis_key
    attr_accessor :storage
    attr_accessor :disguise
    attr_accessor :disguise_url

    def initialize(app_id, app_secret, disguise = false, disguise_url = nil, redis_key=nil)
      @app_id     = app_id
      @app_secret = app_secret
      @expired_at = Time.now.to_i
      @redis_key  = security_redis_key((redis_key || "weixin_" + app_id))
      @storage    = Storage.init_with(self)
      @disguise   = disguise
      @disguise_url = disguise_url
    end

    # return token
    def get_access_token
      @storage.access_token
    end

    # 检查appid和app_secret是否有效。
    def is_valid?
      @storage.valid?
    end

    private

      def access_token_param
        {access_token: get_access_token}
      end

      def http_get(url, headers={}, endpoint="plain")
        headers = headers.merge(access_token_param)
        if @disguise && !@disguise_url.nil?
          get_url = get_disguise_url(@disguise_url, headers)
          return WeixinAuthorize.http_get_disguise_url(get_url, {})
        end
        WeixinAuthorize.http_get_without_token(url, headers, endpoint)
      end

      def http_post(url, payload={}, headers={}, endpoint="plain")
        headers = access_token_param.merge(headers)
        if @disguise && !@disguise_url.nil?
          post_url = get_disguise_url(@disguise_url, headers)
          return WeixinAuthorize.http_post_disguise_url(post_url, payload, {})
        end
        WeixinAuthorize.http_post_without_token(url, payload, headers, endpoint)
      end

      def get_disguise_url(disguise_url, headers = {})
        _url = headers.to_a.map{|x| "#{x[0]}=#{x[1]}" }.join("&")
        disguise_url.include?('?') ? "#{disguise_url}&#{_url}" : "#{disguise_url}?#{_url}"
      end

      def security_redis_key(key)
        Digest::MD5.hexdigest(key.to_s).upcase
      end

  end
end
