# Rake tasks for handling the National Operator Codes spreadsheet
require File.dirname(__FILE__) +  '/data_loader'
namespace :noc do

  include DataLoader

  namespace :load do

    desc "Loads operators from a CSV file specified as FILE=filename"
    task :operators => :environment do
      parse('operators', Parsers::NocParser)
    end

    desc "Loads operator contact information from a CSV file specified as FILE=filename"
    task :operator_contacts => :environment do
      parse('operator_contacts', Parsers::OperatorContactsParser)
    end

    desc "Loads stop area operator information from a CSV file specified as FILE=filename"
    task :station_operators => :environment do
      parse('station_operators', Parsers::OperatorsParser)
    end
  end

end