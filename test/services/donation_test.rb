require 'test_helper'

class OmiseApiTest < ActiveSupport::TestCase
  setup do
    @charity = charities(:children)
  end

  test "that validates omise_token is required" do
    donation = Donation.new(@charity, {amount: 100})

    assert_not donation.valid?
  end

  test "that validates amount is required" do
    donation = Donation.new(@charity, {omise_token: 'token_X'})

    assert_not donation.valid?
  end

  test "that validates amount must be greater than 20" do
    donation = Donation.new(@charity, {omise_token: 'token_X', amount: 20})

    assert_not donation.valid?
  end

  test "that we can't create donation without omise_token" do
    donation = Donation.new(@charity, {amount: 20})

    assert_not donation.create
  end

  test "that we can't create donation without amount" do
    donation = Donation.new(@charity, {omise_token: 'token_X'})

    assert_not donation.create
  end

  test "that we can't create donation with amount less than or equal to 20" do
    [19, 20].each do |amount|
      donation = Donation.new(@charity, {omise_token: 'token_X', amount: amount})

      assert_not donation.create
    end
  end

  test "that we can't create donation in case the failure of omise API" do
    donation = Donation.new(@charity, {omise_token: 'token_X', amount: 100})

    OmiseApi.stub(:create_charge, OpenStruct.new(paid: false)) do
      assert_not donation.create
    end
    OmiseApi.stub(:create_charge, nil) do
      assert_not donation.create
    end
  end

  test "that we can't create donation in case of any failure with transaction" do
    donation = Donation.new(@charity, {omise_token: 'token_X', amount: 100})

    @charity.stub(:credit_amount, false) do
      assert_not donation.create
    end
  end

  test "that we can create donation with some amount" do
    donation = Donation.new(@charity, {omise_token: 'token_X', amount: 100})
    total_amount = 100 * 100
    charity_balance = @charity.total
    charge_stub = OpenStruct.new(amount: total_amount, paid: true)

    OmiseApi.stub(:create_charge, charge_stub) do
      assert donation.create
      assert_equal @charity.reload.total, charity_balance + total_amount
    end
  end

  test "that we can create donation with some amount and subunits" do
    donation = Donation.new(@charity, {omise_token: 'token_X', amount: 100, subunits: 50})
    total_amount = 100 * 100 + 50
    charity_balance = @charity.total
    charge_stub = OpenStruct.new(amount: total_amount, paid: true)

    OmiseApi.stub(:create_charge, charge_stub) do
      assert donation.create
      assert_equal @charity.reload.total, charity_balance + total_amount
    end
  end
end
