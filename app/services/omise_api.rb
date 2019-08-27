module OmiseApi
  def self.create_charge(charity, parameters)
    begin
      Omise::Charge.create({
        amount: total_amount(parameters[:amount], parameters[:subunits]),
        currency: Charity::DEFAULT_CURRENCY,
        card: parameters[:omise_token],
        description: "Donation to #{charity.name} [#{charity.id}]",
      })
    rescue Omise::Error => e
      # handle error for bad request here.
      nil
    end
  end

  def self.retrieve_token(token)
    return nil if token.blank?

    begin
      Omise::Token.retrieve(token)
    rescue Omise::Error => e
      # handle error for invalid token here.
      nil
    end
  end

  private

  def self.total_amount(amount, subunits)
    amount.to_i * 100 + subunits.to_i
  end
end
