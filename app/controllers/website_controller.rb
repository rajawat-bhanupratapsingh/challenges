class WebsiteController < ApplicationController
  def index
    @token = nil
  end

  def donate
    charity = @app.find_or_random_charity(params[:charity])
    donation = Donation.new(charity, donation_params)

    if donation.create
      flash.notice = t(".success")
      redirect_to root_path
    else
      @token = OmiseApi.retrieve_token(params[:omise_token])
      # Note: Can flash donation validation errros as well.
      flash.now.alert = t(".failure")
      render :index
    end
  end

  private

  def donation_params
    params.permit(:charity, :amount, :subunits, :omise_token)
  end
end
