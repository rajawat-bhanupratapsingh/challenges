class WebsiteController < ApplicationController
  before_action :check_for_omise_token, only: [:donate]
  before_action :check_for_amount, only: [:donate]

  def index
    @token = nil
  end

  def donate
    charity = @app.find_or_random_charity(params[:charity])

    if charity.nil?
      handle_failure(nil)
      return render(:index)
    end

    charge = OmiseApi.create_charge(charity, charge_params)

    if charge && charge.paid
      charity.credit_amount(charge.amount)
      flash.notice = t(".success")
      redirect_to root_path
    else
      handle_failure(params[:omise_token])
      render :index
    end
  end

  private

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

  def charge_params
    params.permit(:amount, :subunits, :omise_token)
  end

  def handle_failure(token)
    @token = OmiseApi.retrieve_token(token)
    flash.now.alert = t(".failure")
  end
end
