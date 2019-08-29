module OmiseApi
  def self.create_charge(charity, parameters)
    if charity.blank? || !required_parameters?(parameters)
      return nil
    end

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
    total = amount.to_i * 100
    total += subunits.to_i if subunits.present?
    total
  end

  def self.required_parameters?(parameters)
    parameters = parameters.symbolize_keys if parameters.is_a?(Hash)
    parameters.has_key?(:amount) && parameters.has_key?(:omise_token)
  end
end
