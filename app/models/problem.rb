class Problem < ActiveRecord::Base
  belongs_to :location, :polymorphic => true
  belongs_to :reporter, :class_name => 'User'
  belongs_to :transport_mode
  belongs_to :operator
  belongs_to :passenger_transport_executive
  belongs_to :campaign, :autosave => true
  has_many :assignments
  has_many :updates
  validates_presence_of :transport_mode_id, :unless => :location
  validates_presence_of :description, :subject, :category, :reporter_name, :if => :location
  validate :validate_location_attributes
  validates_associated :reporter
  attr_accessor :location_attributes, :locations, :location_search, :location_errors
  cattr_accessor :route_categories, :stop_categories
  after_create :send_confirmation_email
  before_create :generate_confirmation_token
  has_status({ 0 => 'New', 
               1 => 'Confirmed', 
               2 => 'Fixed',
               3 => 'Hidden' })
  
  named_scope :confirmed, :conditions => ["status_code = ?", self.symbol_to_status_code[:confirmed]], :order => "confirmed_at desc"
  named_scope :unsent, :conditions => ['sent_at is null'], :order => 'confirmed_at desc'
  named_scope :with_operator, :conditions => ['operator_id is not null'], :order => 'confirmed_at desc'
  
  [:responsible_organizations, 
   :emailable_organizations, 
   :unemailable_organizations, 
   :councils_responsible?,
   :pte_responsible?,
   :operators_responsible? ].each { |method| delegate method, :to => :location }
  
  @@route_categories = ['New route needed', 'Keep existing route', 'Crowding', 'Lateness', 'Other']
  @@stop_categories = ['Repair needed', 'Facilities needed', 'Other']
  
  has_paper_trail
  
  # Makes a random token, suitable for using in URLs e.g confirmation messages.
  def generate_confirmation_token
    self.token = MySociety::Util.generate_token
  end
  
  def send_confirmation_email
    ProblemMailer.deliver_problem_confirmation(reporter, self, token)
  end
  
  def validate_location_attributes
    return true if location
    if ! location_attributes_valid?
      errors.add(:location_attributes, ActiveRecord::Error.new(self, :location_attributes, :blank).to_s)
    end
  end
  
  def location_attributes_valid?
    if ! location_attributes or (location_attributes[:name].blank? and
                       location_attributes[:area].blank? and
                       location_attributes[:route_number].blank?)
      return false
    else
      return true
    end
  end
  
  def location_from_attributes
    self.locations = []
    return unless transport_mode_id
    return unless location_attributes_valid?
    location_attributes[:transport_mode_id] = transport_mode_id
    if !location_attributes[:route_number].blank? and location_attributes[:name].blank?
      location_search.add_method('Gazetteer.find_routes_from_attributes') if location_search
      results = Gazetteer.find_routes_from_attributes(location_attributes, :limit => MAX_LOCATION_RESULTS)
    else
      location_search.add_method('Gazetteer.find_stops_and_stations_from_attributes') if location_search
      results = Gazetteer.find_stops_and_stations_from_attributes(location_attributes, :limit => MAX_LOCATION_RESULTS)
    end
    self.locations = results[:results]
    self.location_errors = results[:errors]
    if self.locations.empty? && self.location_errors.empty? 
      self.location_errors << :problem_location_not_found
    end
  end
  
  def create_assignments
    assignment_types = []
    if assignments.empty? 
      assignment_types << { :name => 'publish-problem',
                            :status => :in_progress, 
                            :data => {} }
      if !responsible_organizations.empty? 
        if emailable_organizations.size > 0
          assignment_types << { :name => 'write-to-transport-organization', 
                                :status => :in_progress, 
                                :data => {:organizations => organization_info(:emailable_organizations) }}
        end
        if unemailable_organizations.size > 0
          assignment_types << { :name => 'find-transport-organization-contact-details', 
                                :status => :new, 
                                :data => {:organizations => organization_info(:unemailable_organizations) }}
        end
      else
        assignment_types << { :name => 'find-transport-organization', 
                              :status => :new, 
                              :data => {} }
      end
    end
    assignment_types.each do |data|
      assignment_attributes = { :task_type_name => data[:name], 
                                :status => data[:status],
                                :user => reporter,
                                :data => data[:data],
                                :problem => self }
      Assignment.create_assignment(assignment_attributes)
    end
  end
  
  def responsible_organizations
    if operators_responsible? && operator
      return [operator]
    end
    return location.responsible_organizations
  end
  
  def emailable_organizations
    responsible_organizations.select{ |organization| organization.emailable? }
  end
  
  def unemailable_organizations
    responsible_organizations.select{ |organization| !organization.emailable? }
  end
  
  def organization_info(method)
    self.send(method).map{ |organization| { :id => organization.id, 
                                            :type => organization.class.to_s, 
                                            :name => organization.name } }
  end
  
  def first_sent_to
    writing_assignment = assignments.completed.find(:first, 
                                                    :conditions => ['task_type_name = ?',
                                                                    'write-to-transport-organization'],
                                                    :order => 'updated_at')
    organization_names = writing_assignment.data[:organizations].map{ |organization| organization[:name] }
    organization_names.to_sentence
  end
  
  # if this email has never been used before, assign the name 
  def reporter_attributes=(attributes)
    self.reporter = User.find_or_initialize_by_email(:email => attributes[:email], :name => reporter_name)
  end
  
  # save the user account if none exists, but don't log it in 
  def save_reporter
    if self.reporter.new_record?
      self.reporter.save_without_session_maintenance
    end
  end
  
  def anonymous
    !reporter_public
  end
  
  def anonymous?
    !reporter_public?
  end
  
  # class methods
  
  # Sendable reports - confirmed, with operator, PTE, or council, but not sent
  def self.sendable
    confirmed.unsent.find(:all, :conditions => ['(operator_id is not null
                                                  OR council_info is not null
                                                  OR passenger_transport_executive_id is not null)'])
  end
  
  def self.categories(problem)
    if problem.location.is_a? Route 
      return route_categories
    else
      return stop_categories
    end
  end
  
end