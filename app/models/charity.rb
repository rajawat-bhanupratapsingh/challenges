class Charity < ActiveRecord::Base
  SUBUNITS = [25, 50, 75].freeze

  validates :name, presence: true

  def credit_amount(amount)
    with_lock do
      new_total = total + amount
      update_attribute :total, new_total
    end
  end
end
