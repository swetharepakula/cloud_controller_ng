require 'presenters/api/service_broker_presenter'

module VCAP::CloudController

  # This controller is an experiment breaking away from the old
  # cloudcontroller metaprogramming. We manually generate the JSON
  # expected by CFoundry and CF.
  class ServiceBrokersController < RestController::ModelController
    define_attributes do
      attribute :name,       String
      attribute :broker_url, String
      attribute :auth_username,   String
      attribute :auth_password,   String
    end

    query_parameters :name

    def inject_dependencies(dependencies)
      super
      @services_event_repository = dependencies.fetch(:services_event_repository)
    end

    def create
      validate_access(:create, ServiceBroker)
      params = CreateMessage.decode(body).extract
      broker = ServiceBroker.new(params)

      registration = VCAP::Services::ServiceBrokers::ServiceBrokerRegistration.new(broker)

      unless registration.create
        raise get_exception_from_errors(registration)
      end

      @services_event_repository.create_audit_event('audit.broker.create', broker, params)

      if !registration.warnings.empty?
        registration.warnings.each { |warning| add_warning(warning) }
      end

      headers = {'Location' => url_of(broker)}
      body = ServiceBrokerPresenter.new(broker).to_json
      [HTTP::CREATED, headers, body]
    end

    def update(guid)
      validate_access(:update, ServiceBroker)
      params = UpdateMessage.decode(body).extract
      broker = ServiceBroker.find(guid: guid)
      return HTTP::NOT_FOUND unless broker

      broker.set(params)
      registration = VCAP::Services::ServiceBrokers::ServiceBrokerRegistration.new(broker)

      unless registration.update
        raise get_exception_from_errors(registration)
      end

      @services_event_repository.create_audit_event('audit.broker.update', broker, params)

      if !registration.warnings.empty?
        registration.warnings.each { |warning| add_warning(warning) }
      end

      body = ServiceBrokerPresenter.new(broker).to_json
      [HTTP::OK, {}, body]
    end

    def delete(guid)
      validate_access(:delete, ServiceBroker)
      broker = ServiceBroker.find(:guid => guid)
      return HTTP::NOT_FOUND unless broker

      VCAP::Services::ServiceBrokers::ServiceBrokerRemover.new(broker).execute!
      @services_event_repository.create_audit_event('audit.broker.delete', broker, {})

      HTTP::NO_CONTENT
    rescue Sequel::ForeignKeyConstraintViolation
      raise VCAP::Errors::ApiError.new_from_details("ServiceBrokerNotRemovable")
    end

    def self.translate_validation_exception(e, _)
      if e.errors.on(:name) && e.errors.on(:name).include?(:unique)
        Errors::ApiError.new_from_details("ServiceBrokerNameTaken", e.model.name)
      elsif e.errors.on(:broker_url) && e.errors.on(:broker_url).include?(:unique)
        Errors::ApiError.new_from_details("ServiceBrokerUrlTaken", e.model.broker_url)
      else
        Errors::ApiError.new_from_details("ServiceBrokerCatalogInvalid", e.errors.full_messages)
      end
    end

    define_messages
    define_routes

    private

    def create_audit_event(type, broker, params)
      user = SecurityContext.current_user

      request_hash = {}
      [:name, :broker_url, :auth_username].each do |key|
        request_hash[key] = params[key] unless params[key].nil?
      end

      metadata = {}
      if request_hash.length > 0
        metadata[:request] = request_hash
      end

      Event.create(
          type: type,
          actor_type: 'user',
          actor: user.guid,
          actor_name: SecurityContext.current_user_email,
          timestamp: Time.now,
          actee: broker.guid,
          actee_type: 'broker',
          actee_name: broker.name,
          space_guid: '',           #empty since brokers don't associate to spaces
          organization_guid: '',
          metadata: metadata,
        )
    end

    def url_of(broker)
      "#{self.class.path}/#{broker.guid}"
    end

    def get_exception_from_errors(registration)
      errors = registration.errors
      broker = registration.broker

      if errors.on(:broker_url) && errors.on(:broker_url).include?(:url)
        Errors::ApiError.new_from_details("ServiceBrokerUrlInvalid", broker.broker_url)
      elsif errors.on(:broker_url) && errors.on(:broker_url).include?(:unique)
        Errors::ApiError.new_from_details("ServiceBrokerUrlTaken", broker.broker_url)
      elsif errors.on(:name) && errors.on(:name).include?(:unique)
        Errors::ApiError.new_from_details("ServiceBrokerNameTaken", broker.name)
      elsif errors.on(:services)
        Errors::ApiError.new_from_details("ServiceBrokerInvalid", errors.on(:services))
      else
        Errors::ApiError.new_from_details("ServiceBrokerInvalid", errors.full_messages)
      end
    end
  end
end
