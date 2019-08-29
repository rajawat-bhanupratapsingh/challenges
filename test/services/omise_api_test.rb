require 'test_helper'

class OmiseApiTest < ActiveSupport::TestCase
  setup do
    @charity = charities(:children)
  end

  test "that we can create omise charge with some amount" do
    total_amount = 100 * 100
    charge_stub = OpenStruct.new(amount: total_amount, paid: true)

    Omise::Charge.stub(:create, charge_stub) do
      charge = OmiseApi.create_charge(@charity, amount: 100, omise_token: "tokn_X")

      assert_equal charge.amount, total_amount
      assert charge.paid
    end
  end

  test "that we can create omise charge with some amount and subunits" do
    total_amount = 100 * 100 + 50
    charge_stub = OpenStruct.new(amount: total_amount, paid: true)

    Omise::Charge.stub(:create, charge_stub) do
      charge = OmiseApi.create_charge(@charity, amount: 100, subunits: 50, omise_token: "tokn_X")

      assert_equal charge.amount, total_amount
      assert charge.paid
    end
  end

  test "that we can't create omise charge without charity" do
    charge = OmiseApi.create_charge("", amount: 100, omise_token: "tokn_X")
    assert_nil charge
  end

  test "that we can't create omise charge if amount is 0" do
    charge_stub = OpenStruct.new(paid: false)

    Omise::Charge.stub(:create, charge_stub) do
      charge = OmiseApi.create_charge(@charity, amount: 0, omise_token: "tokn_X")

      assert_not charge.paid
    end
  end

  test "that we can't create omise charge if amount is less than 20" do
    charge_stub = OpenStruct.new(paid: false)

    Omise::Charge.stub(:create, charge_stub) do
      charge = OmiseApi.create_charge(@charity, amount: 19, omise_token: "tokn_X")

      assert_not charge.paid
    end
  end

  test "that we can't create omise charge without token" do
    charge = OmiseApi.create_charge(@charity, amount: 100, omise_token: "")

    assert_nil charge
  end

  test "that we can't create omise charge if the charge fail from omise side" do
    charge_stub = Proc.new { raise Omise::Error.new(code: "X", message: "test") }

    Omise::Charge.stub(:create, charge_stub) do
      charge = OmiseApi.create_charge(@charity, amount: 100, omise_token: "tokn_X")

      assert_nil charge
    end
  end

  test "that we can retrieve omise token with a valid token" do
    Omise::Token.stub(:retrieve, "retrieved_token_X") do
      token = OmiseApi.retrieve_token("tokn_X")

      assert_equal token, "retrieved_token_X"
    end
  end

  test "that we can't retrieve omise token from omise side without token" do
    Omise::Token.stub(:retrieve, nil) do
      token = OmiseApi.retrieve_token("")

      assert_nil token
    end
  end

  test "that we can't retrieve omise token from omise side with invalid token" do
    token_stub = Proc.new { raise Omise::Error.new(code: "X", message: "test") }

    Omise::Token.stub(:retrieve, token_stub) do
      token = OmiseApi.retrieve_token("invalid_token")

      assert_nil token
    end
  end
end
