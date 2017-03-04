module Api
  class PagesController < ApplicationController
    before_action :get_params, except: :redis_ping

    def graph
      result = JSON.parse($redis.get(params[:keyword])) || {'graph' => {}}
      render json: result['graph']
    rescue => e
      render json: {message: e.message}, status: :internal_server_error
    end

    def data_graph
      result = JSON.parse($redis.get(params[:keyword])) || {'data_graph' => {}}
      render json: result['data_graph']
    rescue => e
      render json: {message: e.message}, status: :internal_server_error
    end

    def redis_ping
      $redis.set('ping', 'pong')
      render json: $redis.get('ping')
    rescue => e
      render json: {message: e.message}, status: :internal_server_error
    end

    def projects
      keyword = JSON.parse $redis.get(params[:keyword])
      if keyword.present? && keyword[:projects].present?
        projects = keyword[:projects]
      else
        projects = []
      end
      render json: projects
    rescue => e
      render json: {message: e.message}, status: :internal_server_error
    end

    private

    def get_params
      raise 'missing argument \'keyword\'' if params[:keyword].blank?
    end    
  end
end
