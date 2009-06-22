$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'test/unit'
require 'hatenadiary'

module TU_CommonSetup
  def common_setup
    @username = 'HATENA_ID'
    @password = 'PASSWORD'
    @agent = TU_MechanizeMock.new
    TU_MechanizeMock.queue.push @agent
    TU_MechanizeMock::DUMMY_ACCOUNTS[@username] = @password
    HatenaDiary::Client.mechanizer = TU_MechanizeMock
  end
end

class TC_HatenaDiary < Test::Unit::TestCase
  include TU_CommonSetup
  
  def setup
    common_setup
  end
  
  def test_login
    HatenaDiary.login(@username, @password) do |client|
      assert client.login?
    end
  end
end

class TC_HatenaDiary_Client_class < Test::Unit::TestCase
  include TU_CommonSetup
  
  def setup
    common_setup
  end
  
  def test_login
    HatenaDiary::Client.login(@username, @password) do |client|
      assert_kind_of HatenaDiary::Client, client
      assert client.login?
    end
  end
  
  def test_login_without_block
    client = HatenaDiary::Client.login(@username, @password)
    assert_kind_of HatenaDiary::Client, client
    assert !@agent.proxy
  end
  
  def test_login_without_block_with_proxy
    client = HatenaDiary::Client.login(@username, @password, ['URL', 666])
    assert_equal ['URL', 666], @agent.proxy
  end
end

class TC_HatenaDiary_Client < Test::Unit::TestCase
  include TU_CommonSetup
  
  def setup
    common_setup
    @client = HatenaDiary::Client.new(@username, @password)
  end
  
  def test_set_proxy
    @client.set_proxy('URL', 666)
    assert_equal @agent.proxy, ['URL', 666]
  end
  
  def test_login_and_logout
    assert !@client.login?
    @client.login
    assert @client.login?
    @client.logout
    assert !@client.login?
  end
  
  def test_login_failure
    TU_MechanizeMock::DUMMY_ACCOUNTS.delete('no_one')
    begin
      @client.login 'no_one', 'password?'
      flunk
    rescue HatenaDiary::LoginError => ex
      assert_kind_of HatenaDiary::LoginError, ex
      assert_equal 'no_one', ex.username
      assert_equal 'password?', ex.password
    end
  end
  
  def test_login_if_hatena_changed
    @agent.with_login_page_result_title 'jumbled page title :-)' do
      @client.login
    end
    flunk
  rescue Exception => ex
    assert /must not happen/ =~ ex.message
  end
  
  def test_transaction
    assert !@client.login?
    @client.transaction do |client|
      assert_same @client, client
      assert @client.login?
    end
    assert !@client.login?
  end
  
  def test_transaction_without_block
    assert !@client.login?
    assert_raises LocalJumpError do
      @client.transaction
    end
    assert !@client.login?
  end
  
  def test_post
    @client.transaction do |client|
      client.post 1234, 5, 6, "TITLE", "BODY\n"
    end
    h = @agent.latest_post_form
    assert_equal "1234",   h["year"]
    assert_equal "05",     h["month"]
    assert_equal "06",     h["day"]
    assert_equal "TITLE",  h["title"]
    assert_equal "BODY\n", h["body"]
  end
  
  def test_post_trivial
    @client.transaction do |client|
      client.post 2000, 7, 8, "TITLE", "BODY\n", true
    end
    h = @agent.latest_post_form
    assert_equal "edit",   h[:form_id]
    assert_equal "2000",   h["year"]
    assert_equal "07",     h["month"]
    assert_equal "08",     h["day"]
    assert_equal "TITLE",  h["title"]
    assert_equal "BODY\n", h["body"]
    assert_equal "true",   h["trivial"]
  end
  
  def test_post_without_login
    assert_raises HatenaDiary::LoginError do
      @client.post 1999, 5, 26, "TITLE", "BODY\n"
    end
  end
  
  def test_delete
    @client.transaction do |client|
      client.delete 1234, 5, 6
    end
    h = @agent.latest_post_form
    assert_equal "delete", h[:form_id]
    assert_equal "1234",   h["year"]
    assert_equal "05",     h["month"]
    assert_equal "06",     h["day"]
  end
  
  def test_delete_without_login
    assert_raises HatenaDiary::LoginError do
      @client.delete 2009, 8, 30
    end
  end
end

class TU_MechanizeMock
  def self.queue
    @queue ||= []
  end
  
  def self.new
    queue.shift or super
  end
  
  def set_proxy(url, port)
    @proxy = [url, port]
  end
  
  attr_reader :proxy
  attr_reader :latest_post_form
  
  def with_login_page_result_title(title, &block)
    @preset_title = title
    yield()
  ensure
    @preset_title = nil
  end
  
  DUMMY_ACCOUNTS = {}
  
  def get(url)
    case url
    when "https://www.hatena.ne.jp/login"
      forms = []
      forms << create_form{|form|
        form["persistent"] == "true" or throw :test_hatenadiary_mechanizemock_login_form_not_persistent
        if @preset_title
          Page.new(@preset_title)
        else
          Page.new(DUMMY_ACCOUNTS[form["name"]] == form["password"] ? "Hatena" : "Login - Hatena")
        end
      }
      Page.new(nil, forms)
    when "https://www.hatena.ne.jp/logout"
      Page.new
    when %r[\Ahttp://d.hatena.ne.jp/]
      id, rest = $'.split('/', 2)
      addr, query = rest.split('?', 2)
      forms = [nil, nil, nil]
      forms.unshift create_form{|form|
        form[:form_id] = "edit"
        @latest_post_form = form
      }
      forms.push create_form{|form|
        form[:form_id] = "delete"
        @latest_post_form = form
      }
      Page.new(nil, forms)
    end
  end
  
  Page = Struct.new(:title, :forms)
  
  def create_form(&block)
    form = { :__submitter__ => block }
    def form.submit
      fetch(:__submitter__).call(self)
    end
    form
  end
end
