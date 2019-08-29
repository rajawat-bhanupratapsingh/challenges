require "test_helper"

class WebsiteTest < ActionDispatch::IntegrationTest
  OMISE_TOKEN = OpenStruct.new({
    id: "tokn_X",
    card: OpenStruct.new({
      name: "J DOE",
      last_digits: "4242",
      expiration_month: 10,
      expiration_year: 2020,
      security_code_check: false,
    }),
  })

  test "should get index" do
    get "/"

    assert_response :success
  end

  test "that someone can't donate to no charity" do
    post(donate_path, params: {
           amount: "100", omise_token: "tokn_X", charity: ""
         })

    assert_template :index
    assert_equal t("website.donate.failure"), flash.now[:alert]
  end

  test "that someone can't donate 0 to a charity" do
    charity = charities(:children)
    OmiseApi.stub(:retrieve_token, OMISE_TOKEN) do
      post(donate_path, params: {
             amount: "0", omise_token: "tokn_X", charity: charity.id
           })
    end

    assert_template :index
    assert_equal t("website.donate.failure"), flash.now[:alert]
  end

  test "that someone can't donate less than 20 to a charity" do
    charity = charities(:children)
    OmiseApi.stub(:retrieve_token, OMISE_TOKEN) do
      post(donate_path, params: {
             amount: "19", omise_token: "tokn_X", charity: charity.id
           })
    end

    assert_template :index
    assert_equal t("website.donate.failure"), flash.now[:alert]
  end

  test "that someone can't donate without a token" do
    charity = charities(:children)
    post(donate_path, params: {
           amount: "100", charity: charity.id
         })

    assert_template :index
    assert_equal t("website.donate.failure"), flash.now[:alert]
  end

  test "that someone can donate to a charity" do
    charity = charities(:children)
    initial_total = charity.total
    total_amount = 100 * 100
    expected_total = initial_total + total_amount
    charge_stub = OpenStruct.new(amount: total_amount, paid: true)

    OmiseApi.stub(:create_charge, charge_stub) do
      post(donate_path, params: {
             amount: "100", omise_token: "tokn_X", charity: charity.id
           })
    end
    follow_redirect!

    assert_template :index
    assert_equal t("website.donate.success"), flash[:notice]
    assert_equal expected_total, charity.reload.total
  end

  test "that someone can donate some amount with subunits to a charity" do
    charity = charities(:children)
    initial_total = charity.total
    total_amount = 100 * 100 + 25
    expected_total = initial_total + total_amount
    charge_stub = OpenStruct.new(amount: total_amount, paid: true)

    OmiseApi.stub(:create_charge, charge_stub) do
      post(donate_path, params: {
             amount: "100", subunits: "25", omise_token: "tokn_X", charity: charity.id
           })
    end
    follow_redirect!

    assert_template :index
    assert_equal t("website.donate.success"), flash[:notice]
    assert_equal expected_total, charity.reload.total
  end

  test "that if the charge fail from omise side it shows an error" do
    charity = charities(:children)
    charge_stub = OpenStruct.new(paid: false)

    OmiseApi.stub(:create_charge, charge_stub) do
      OmiseApi.stub(:retrieve_token, OMISE_TOKEN) do
        post(donate_path, params: {
               amount: "999", omise_token: "tokn_X", charity: charity.id
             })
      end
    end

    assert_template :index
    assert_equal t("website.donate.failure"), flash.now[:alert]
  end

  test "that we can donate to a charity at random" do
    charities = Charity.all
    initial_total = charities.to_a.sum(&:total)
    total_amount = 100 * 100
    expected_total = initial_total + total_amount
    charge_stub = OpenStruct.new(amount: total_amount, paid: true)

    OmiseApi.stub(:create_charge, charge_stub) do
      post(donate_path, params: {
             amount: "100", omise_token: "tokn_X", charity: "random"
           })
    end
    follow_redirect!

    assert_template :index
    assert_equal expected_total, charities.to_a.map(&:reload).sum(&:total)
    assert_equal t("website.donate.success"), flash[:notice]
  end
end
