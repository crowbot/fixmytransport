require File.dirname(__FILE__) +  '/data_loader'
namespace :nptg do
  
  include DataLoader
  
  namespace :match do 
  
    desc 'Matches stops to localities using the nptg_locality_code field' 
    task :stops_to_localities => :environment do 
      Stop.find_each do |stop|
        locality = Locality.find_by_code(stop.nptg_locality_code)
        stop.locality = locality
        stop.save!
      end
    end
    
  end
  
  namespace :load do
    
    desc "Loads regions from a CSV file specified as FILE=filename"
    task :regions => :environment do 
      parse('regions', Parsers::NptgParser)
    end
  
    desc "Loads admin area data from a CSV file specified as FILE=filename"
    task :admin_areas => :environment do 
      parse('admin_areas', Parsers::NptgParser)
    end     

    desc "Loads district from a CSV file specified as FILE=filename"
    task :districts => :environment do 
      parse('districts', Parsers::NptgParser)
    end
    
    desc "Loads locality data from a CSV file specified as FILE=filename"
    task :localities => :environment do 
      parse('localities', Parsers::NptgParser)
    end
    
    desc "Loads locality hierarchy data from a CSV file specified as FILE=filename"
    task :locality_hierarchy => :environment do 
      parse('locality_hierarchy', Parsers::NptgParser)
    end
    
    desc "Loads locality alternative name data from a CSV file specified as FILE=filename"
    task :locality_alternative_names => :environment do 
      parse('locality_alternative_names', Parsers::NptgParser)
    end
    
    desc "Updates districts with the admin areas given in the locality data" 
    task :add_district_admin_areas => :environment do 
      District.find_each do |district|
        admin_areas = district.localities.map{ |locality| locality.admin_area }.uniq
        puts "#{district.name} has #{district.localities.size} localities"
        raise "More than one admin area for district #{district.name} #{admin_areas.inspect}" unless admin_areas.size <= 1
        district.admin_area = admin_areas.first
        district.save!
      end
    end
        
    desc "Loads all data from CSV files in a directory specified as DIR=dirname"
    task :all => :environment do 
      unless ENV['DIR']
        usage_message "usage: rake nptg:load:all DIR=dirname"
      end
      puts "Loading data from #{ENV['DIR']}..."
      ENV['FILE'] = File.join(ENV['DIR'], 'Travel Regions.csv')
      Rake::Task['nptg:load:regions'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'Admin Areas.csv')
      Rake::Task['nptg:load:admin_areas'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'Districts.csv')
      Rake::Task['nptg:load:districts'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'Localities.csv')
      Rake::Task['nptg:load:localities'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'Hierarchy.csv')
      Rake::Task['nptg:load:locality_hierarchy'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'Alternate Names.csv')
      Rake::Task['nptg:load:locality_alternative_names'].execute
      Rake::Task['nptg:load:add_district_admin_areas'].execute
    end
    
  end
  

  
end