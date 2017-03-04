module Api
  class PagesController < ApplicationController
    def graph
      raise 'missing argument \'keyword\'' if params[:keyword].blank?
      result = JSON.parse($redis.get(params[:keyword])) || {'graph' => {}}
      render json: result['graph']
    end

    def data_graph
      raise 'missing argument \'keyword\'' if params[:keyword].blank?
      result = JSON.parse($redis.get(params[:keyword])) || {'data_graph' => {}}
      render json: result['data_graph']
    end
  end
end
