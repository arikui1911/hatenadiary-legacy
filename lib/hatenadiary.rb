# 
# Distributes under The modified BSD license.
# 
# Copyright (c) 2009 arikui <http://d.hatena.ne.jp/arikui/>
# All rights reserved.
# 

require 'rubygems'
require 'hpricot'
require 'www/mechanize'
require 'www/mechanize/util'
require 'nkf'

WWW::Mechanize.html_parser = Hpricot

class << WWW::Mechanize::Util
  org = instance_method(:html_unescape)
  define_method(:html_unescape) do |s|
    m = org.bind(self)
    begin
      m.call s
    rescue ArgumentError
      m.call s.force_encoding(NKF.guess(s))
    end
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
    def initialize(username, password)
      @agent = self.class.mechanizer.new
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
    def post(yyyy, mm, dd, title, body, trivial_p = false)
      edit_page(yyyy, mm, dd, 0) do |form|
        form["title"]   = title
        form["body"]    = body
        form["trivial"] = "true" if trivial_p
      end
    end
    
    # Deletes an entry from Hatena diary service.
    # 
    # Raises HatenaDiary::LoginError unless logined.
    def delete(yyyy, mm, dd)
      edit_page(yyyy, mm, dd, -1)
    end
    
    private
    
    def edit_page(yyyy, mm, dd, form_index)
      raise LoginError, "not login yet" unless login?
      response = @agent.get("http://d.hatena.ne.jp/#{@current_account[0]}/edit?date=#{yyyy}#{mm}#{dd}")
      form = response.forms.fetch(form_index)
      form["year"]  = "%04d" % yyyy
      form["month"] = "%02d" % mm
      form["day"]   = "%02d" % dd
      yield(form) if block_given?
      form.submit
    end
  end
end
