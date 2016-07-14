require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'pry'

helpers do
  def calc_total(money)
    total_income = 0

    unless money == nil
      money.each_value do |dollars|
        total_income += dollars.to_i
      end
    end 
    total_income
  end
end

get '/' do    
  erb :home
end

get '/expendable' do
  erb :expendable
end

post '/expendable' do
  @income = calc_total(params[:income])
  @expenses = calc_total(params[:bills])
  @expendable_income = @income - @expenses 
  erb :expendable, layout: :layout
end

get '/mortgage' do
  erb :mortgage
end

post '/mortgage' do
  @income = calc_total(params[:income])
  @expenses = calc_total(params[:bills])
  @mortgage = (((@income * 0.44) - @expenses) * 360).to_i
  erb :mortgage
end
