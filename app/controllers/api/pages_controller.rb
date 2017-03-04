module Api
  class PagesController < ApplicationController
    def graph
      raise 'missing argument \'keyword\'' if params[:keyword].blank?
      result = $redis.get(params[:keyword]) || {graph: {}}
      render json: result
    end
  end
end
