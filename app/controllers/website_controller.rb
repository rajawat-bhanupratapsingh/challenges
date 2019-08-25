class WebsiteController < ApplicationController
  before_action :check_for_omise_token, only: [:donate]
  before_action :check_for_amount, only: [:donate]
  before_action :find_and_check_for_charity, only: [:donate]

  def index
    @token = nil
  end

  def donate
    if Rails.env.test?
      charge = OpenStruct.new({
        amount: total_amount,
        paid: (params[:amount].to_i != 999),
      })
    else
      charge = Omise::Charge.create({
        amount: total_amount,
        currency: "THB",
        card: params[:omise_token],
        description: "Donation to #{@charity.name} [#{@charity.id}]",
      })
    end
    if charge.paid
      @charity.credit_amount(charge.amount)
      flash.notice = t(".success")
      redirect_to root_path
    else
      handle_failure(params[:omise_token])
      render :index
    end
  end

  private

  def retrieve_token(token)
    if Rails.env.test?
      OpenStruct.new({
        id: "tokn_X",
        card: OpenStruct.new({
          name: "J DOE",
          last_digits: "4242",
          expiration_month: 10,
          expiration_year: 2020,
          security_code_check: false,
        }),
      })
    else
      Omise::Token.retrieve(token)
    end
  end

  def total_amount
    params[:amount].to_i * 100 + params[:subunits].to_i
  end

  def check_for_omise_token
    if params[:omise_token].blank?
      handle_failure(nil)
      return render(:index)
    end
  end

  def check_for_amount
    if params[:amount].blank? || params[:amount].to_i <= 20
      handle_failure(params[:omise_token])
      return render(:index)
    end
  end

  def find_and_check_for_charity
    @charity = find_charity(params[:charity])
    if @charity.nil?
      handle_failure(nil)
      return render(:index)
    end
  end

  def find_charity(charity_param)
    if charity_param == "random"
      Charity.all.sample
    else
      @app.find_charity(charity_param)
    end
  end

  def handle_failure(token)
    @token = token.present? ? retrieve_token(token) : nil
    flash.now.alert = t(".failure")
  end
end
