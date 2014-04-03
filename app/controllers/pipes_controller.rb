class PipesController < ApplicationController
  before_filter :require_admin

  def index
    @pipes =  Pipe.paginate :page => params[:page], :order => 'created_at DESC'
  end

  def new
    @pipe = Pipe.new
  end

  def create

  end

end

