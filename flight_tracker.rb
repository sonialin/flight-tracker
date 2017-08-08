require 'sinatra'
require 'sinatra/reloader'
require 'yaml'
require 'date'
require 'time'

configure do
  enable :sessions
end

helpers do
  def arrival_status(arrival_time)
    if Time.parse(arrival_time) > Time.now
      "On the way"
    else
      "Arrived"
    end
  end

  def main_info(flight_info)
    flight_info.select { |key, _| main_fields.include? key }
  end

  def sort_by_time(flights)
    flights.sort_by { |_, info| Time.parse(info['Schedule']) }
  end
end

before do
  load_flights
end

def main_fields
  ['Airline', 'From', 'Schedule', 'Gate']
end

def load_flights
  path = File.expand_path("../flights.yml", __FILE__)
  @flights = YAML.load_file(path)
end

def within_range(arrival_time, searched_time)
  arrival_time = Time.parse(arrival_time)
  searched_time = Time.parse(searched_time)
  (arrival_time - searched_time).abs < 3600
end

def valid_time(input_time)
  if !(Time.parse(input_time) rescue false)
    session[:message] = "This is not a valid time input."
    return false
  end
  true
end

def find_flights_by_number
  flight_number = params[:flight_number].upcase
  if @flights.key? flight_number
    @flights = @flights.select { |key, _| key == flight_number }
  else
    session[:message] = "Please enter a valid flight number."
    redirect "/"
  end
end

def find_flights_by_place_of_departure
  departure_place = params[:place_of_departure].strip.downcase
  @flights = @flights.select { |_, info| info['From'].downcase.include? departure_place }
end

def narrow_down_flights_by_arrival_time
  arrival_time = params[:arrival_time]
  @flights = @flights.select { |_, info| within_range(info['Schedule'], arrival_time) }
end

get "/" do
  if params[:flight_number]
    find_flights_by_number
  elsif params[:place_of_departure]
    find_flights_by_place_of_departure
    if !params[:arrival_time].empty? && valid_time(params[:arrival_time])
      narrow_down_flights_by_arrival_time
    end
  end

  if @flights.empty?
    session[:message] = "There is no flight matching the search criteria."
  end
  erb :index
end

get "/:flight_number" do
  @flight_number = params[:flight_number]
  if @flights.key?(@flight_number)
    @flight_info = @flights[@flight_number]
    erb :view
  else
    session[:message] = "Please enter a valid flight number."
    redirect "/"
  end
end
