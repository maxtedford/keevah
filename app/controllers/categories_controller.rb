class CategoriesController < ApplicationController
  def index
    @category = Category.all
  end

  def show
    @category = Category.find(params[:id])
    @loan_requests = @category.loan_requests.paginate(:page => params[:page], :per_page => 20)
    @categories = Category.all
  end
end
