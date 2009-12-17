# 
# Distributes under The modified BSD license.
# 
# Copyright (c) 2009 arikui <http://d.hatena.ne.jp/arikui1911/>
# All rights reserved.
# 

require 'rubygems'
require 'nokogiri'
require 'mechanize'

# depend on Ruby version
module HatenaDiary
  module Util
    if RUBY_VERSION >= '1.9'
      def encode_to_utf8(str)
        str.encode(Encoding::UTF_8)
      end
    else
      require 'kconv'
      
      def encode_to_utf8(str)
        Kconv.toutf8(str)
      end
    end
    
    module_function :encode_to_utf8
  end
end


module HatenaDiary
  # 
  # Allocates Client object and makes it login, execute a received block,
  # and then logout.
  # 
  # :call-seq:
  #   login(username, password, proxy = nil){|client| ... }
  # 
  def login(*args, &block)
    Client.login(*args, &block)
  end
  module_function :login
  
  class LoginError < RuntimeError
    def set_account(username, password)
      @username = username
      @password = password
      self
    end
    
    attr_reader :username
    attr_reader :password
  end
  
  class Client
    def self.mechanizer
      @mechanizer ||= WWW::Mechanize
    end
    
    def self.mechanizer=(klass)
      @mechanizer = klass
    end
    
    # Allocates Client object.
    # 
    # If block given, login and execute a received block, and then logout ensurely.
    # 
    # [username] Hatena ID
    # [password] Password for _username_
    # [proxy] Proxy configuration; [proxy_url, port_no] | nil
    # 
    def self.login(username, password, proxy = nil, &block)
      client = new(username, password)
      client.set_proxy(*proxy) if proxy
      return client unless block_given?
      client.transaction(&block)
    end
    
    # Allocates Client object.
    # 
    # [username] Hatena ID
    # [password] Password for _username_
    def initialize(username, password, agent = self.class.mechanizer.new)
      @agent = agent
      @username = username
      @password = password
      @current_account = nil
    end
    
    # Configure proxy.
    def set_proxy(url, port)
      @agent.set_proxy(url, port)
    end
    
    # Login and execute a received block, and then logout ensurely.
    def transaction(username = nil, password = nil)
      raise LocalJumpError, "no block given" unless block_given?
      login(username, password)
      begin
        yield(self)
      ensure
        logout
      end
    end
    
    # Returns a client itself was logined or not.
    # 
    # -> true | false
    def login?
      @current_account ? true : false
    end
    
    # Does login.
    # 
    # If _username_ or _password_ are invalid, raises HatenaDiary::LoginError .
    def login(username = nil, password = nil)
      username ||= @username
      password ||= @password
      form = @agent.get("https://www.hatena.ne.jp/login").forms.first
      form["name"]       = username
      form["password"]   = password
      form["persistent"] = "true"
      response = form.submit
      @current_account = [username, password]
      case response.title
      when "Hatena" then response
      when "Login - Hatena" then raise LoginError.new("login failure").set_account(username, password)
      else raise Exception, '[BUG] must not happen (maybe cannot follow hatena spec)'
      end
    end
    
    # Does logout if already logined.
    def logout
      return unless login?
      @agent.get("https://www.hatena.ne.jp/logout")
      account = @current_account
      @current_account = nil
      account
    end
    
    # Posts an entry to Hatena diary service.
    # 
    # Raises HatenaDiary::LoginError unless logined.
    # 
    # options
    # [:trivial] check a checkbox of trivial updating.
    # [:group]   assign hatena-group name. edit group diary.
    #
    # Invalid options were ignored.
    def post(yyyy, mm, dd, title, body, options = {})
      title = Util.encode_to_utf8(title)
      body  = Util.encode_to_utf8(body)
      form = get_form(yyyy, mm, dd, options[:group]){|r| r.form_with(:name => 'edit') }
      form["year"]    = "%04d" % yyyy
      form["month"]   = "%02d" % mm
      form["day"]     = "%02d" % dd
      form["title"]   = title
      form["body"]    = body
      form["trivial"] = "true" if options[:trivial]
      @agent.submit form, form.button_with(:name => 'edit')
    end
    
    # Deletes an entry from Hatena diary service.
    # 
    # Raises HatenaDiary::LoginError unless logined.
    # 
    # options
    # [:group]   assign hatena-group name. edit group diary.
    # 
    # Invalid options were ignored.
    def delete(yyyy, mm, dd, options = {})
      get_form(yyyy, mm, dd, options[:group]){|r| r.forms.last }.submit
    end
    
    private
    
    def get_form(yyyy, mm, dd, group = nil)
      raise LoginError, "not login yet" unless login?
      vals = [group ? "#{group}.g" : "d",
              @current_account[0],
              yyyy, mm, dd]
      yield @agent.get("http://%s.hatena.ne.jp/%s/edit?date=%04d%02d%02d" % vals)
    end
  end
end

