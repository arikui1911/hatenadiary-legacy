require 'test/unit'
require 'flexmock'
require 'hatenadiary'


class TestHatenaDiaryAPI < Test::Unit::TestCase
  include FlexMock::TestCase

  def test_default_mechanizer
    HatenaDiary::Client.mechanizer = nil
    assert_equal Mechanize, HatenaDiary::Client.mechanizer
  end

  def setup
    @username = 'USERNAME'
    @password = 'PASSWORD'
    @proxy_url  = "PROXY_URL"
    @proxy_port = "PROXY_PORT"
  end

  def test_api_login
    flexmock HatenaDiary::Client
    HatenaDiary::Client.should_receive(:login)
    HatenaDiary.login
  end

  def setup_mocks
    flexmock HatenaDiary::Client
    @client = flexmock("client")
  end

  def test_login
    setup_mocks
    HatenaDiary::Client.should_receive(:new).with(@username, @password).and_return(@client)
    @client.should_receive(:transaction).and_yield('block delegate check')
    HatenaDiary::Client.login(@username, @password) do |str|
      assert_equal 'block delegate check', str
    end
  end

  def test_login_with_proxy
    setup_mocks
    HatenaDiary::Client.should_receive(:new).with(@username, @password).and_return(@client)
    @client.should_receive(:set_proxy).with(@proxy_url, @proxy_port)
    @client.should_receive(:transaction).yields('block delegate check')
    HatenaDiary::Client.login(@username, @password,  [@proxy_url, @proxy_port]) do |str|
      assert_equal 'block delegate check', str
    end
  end

  def test_login_without_block
    setup_mocks
    HatenaDiary::Client.should_receive(:new).with(@username, @password).and_return(@client)
    assert_equal @client, HatenaDiary::Client.login(@username, @password)
  end

  def test_login_without_block_with_proxy
    setup_mocks
    HatenaDiary::Client.should_receive(:new).with(@username, @password).and_return(@client)
    @client.should_receive(:set_proxy).with(@proxy_url, @proxy_port)
    assert_equal @client, HatenaDiary::Client.login(@username, @password, [@proxy_url, @proxy_port])
  end
end


class TestHatenaDiary < Test::Unit::TestCase
  include FlexMock::TestCase

  def setup
    @username = 'USERNAME'
    @password = 'PASSWORD'
    @agent = flexmock("agent")
    @client = HatenaDiary::Client.new(@username, @password, @agent)
  end

  def test_set_proxy
    proxy_url  = 'PROXY_URL'
    proxy_port = 'PROXY_PORT'
    @agent.should_receive(:set_proxy).with(proxy_url, proxy_port)
    @client.set_proxy(proxy_url, proxy_port)
  end

  def test_logout_without_login
    @client.logout
  end

  module MockHash
    def [](k)
      (@_table ||= {})[k]
    end

    def []=(k, v)
      (@_table ||= {})[k] = v
    end

    def to_h
      @_table ||= {}
    end
  end

  def login_mocking(submit_response_page_title)
    login_page = flexmock("login_page")
    form = flexmock("form").extend(MockHash)
    forms = [form]
    response = flexmock("response")
    @agent.should_receive(:get).with("https://www.hatena.ne.jp/login").and_return(login_page)
    login_page.should_receive(:forms).and_return(forms)
    form.should_receive(:submit).and_return(response)
    response.should_receive(:title).and_return(submit_response_page_title)
    form
  end

  def logout_mocking
    @agent.should_receive(:get).with("https://www.hatena.ne.jp/logout")
  end

  def test_login_and_logout
    # before login
    assert !@client.login?
    # login
    form = login_mocking("Hatena")
    @client.login
    assert @client.login?
    assert_equal form["name"],       @username
    assert_equal form["password"],   @password
    assert_equal form["persistent"], "true"
    # logout
    logout_mocking
    @client.logout
    assert !@client.login?
  end

  def test_login_failure
    login_mocking "Login - Hatena"
    begin
      @client.login
    rescue HatenaDiary::LoginError => ex
      assert_equal @username, ex.username
      assert_equal @password, ex.password
    else
      flunk "login error must be raised."
    end
  end

  def test_login_if_hatena_changed
    login_mocking "*jumbled pagetitle*"
    begin
      @client.login
    rescue Exception => ex
      assert /must not happen/ =~ ex.message
    else
      flunk "exception must be raised"
    end
  end

  def test_transaction
    assert !@client.login?
    login_mocking "Hatena"
    logout_mocking
    @client.transaction do |client|
      assert @client.equal?(client)
      assert @client.login?
    end
    assert !@client.login?
  end

  def test_transaction_without_block
    assert !@client.login?
    assert_raise LocalJumpError do
      @client.transaction
    end
    assert !@client.login?
  end

  def post_mocking(host, date_str)
    edit_page = flexmock("edit_page")
    form = flexmock("form").extend(MockHash)
    button = Object.new
    login_mocking "Hatena"
    logout_mocking
    @agent.should_receive(:get).with("http://#{host}.hatena.ne.jp/#{@username}/edit?date=#{date_str}").and_return(edit_page)
    edit_page.should_receive(:form_with).with(:name => 'edit').and_return(form)
    form.should_receive(:button_with).with(:name => 'edit').and_return(button)
    @agent.should_receive(:submit).with(form, button)
    form
  end

  def test_post
    form = post_mocking("d", "12340506")
    @client.transaction do |client|
      client.post 1234, 5, 6, 'TITLE', 'BODY'
    end
    expected = {
      "year"  => "1234",
      "month" => "05",
      "day"   => "06",
      "title" => "TITLE",
      "body"  => "BODY",
    }
    assert_equal expected, form.to_h
    assert !form["trivial"]
  end

  def test_post_trivial
    form = post_mocking("d", "20071108")
    @client.transaction do |client|
      client.post 2007, 11, 8, 'TITLE', 'BODY', :trivial => true
    end
    assert_equal "true", form["trivial"]
  end

  def test_post_group
    post_mocking "hoge.g", "12340506"
    @client.transaction do |client|
      client.post 1234, 5, 6, 'TITLE', 'BODY', :group => 'hoge'
    end
  end

  def test_post_group_trivial
    form = post_mocking("hoge.g", "12340506")
    @client.transaction do |client|
      client.post 1234, 5, 6, 'TITLE', 'BODY', :group => 'hoge', :trivial => true
    end
    assert_equal "true", form["trivial"]
  end

  def test_post_without_login
    assert_raise HatenaDiary::LoginError do
      @client.post 1999, 5, 26, "TITLE", "BODY\n"
    end
  end

  def delete_mocking(host, date_str)
    edit_page = flexmock("edit_page")
    form = flexmock("form").extend(MockHash)
    forms = [form]
    button = Object.new
    login_mocking "Hatena"
    logout_mocking
    @agent.should_receive(:get).with("http://#{host}.hatena.ne.jp/#{@username}/edit?date=#{date_str}").and_return(edit_page)
    edit_page.should_receive(:forms).returns(forms)
    form.should_receive(:submit)
    form
  end

  def test_delete
    delete_mocking "d", "12340506"
    @client.transaction do |client|
      client.delete 1234, 5, 6
    end
  end

  def test_delete_group
    delete_mocking "piyo.g", "12340506"
    @client.transaction do |client|
      client.delete 1234, 5, 6, :group => 'piyo'
    end
  end

  def test_delete_without_login
    assert_raise HatenaDiary::LoginError do
      @client.delete 2009, 8, 30
    end
  end
end

