class Donation
  include ActiveModel::Validations

  attr_reader :charity, :omise_token, :amount, :subunits

  validates :omise_token, :amount, presence: true
  validates :amount, numericality: { greater_than: 20 }

  def initialize(charity, params = {})
    @charity = charity
    @omise_token = params[:omise_token]
    @amount = params[:amount].to_i
    @subunits = params[:subunits].to_i
  end

  def create
    return false unless valid?

    result = false
    charge = OmiseApi.create_charge(charity, charge_params)
    if charge && charge.paid
      result = charity.credit_amount(charge.amount)
    end

    return result
  end

  private

  def charge_params
    {
      omise_token: omise_token,
      amount: amount,
      subunits: subunits,
    }
  end
end
