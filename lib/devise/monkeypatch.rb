# Monkeypatch to allow multiple routes for a single module
module Devise
  class Mapping
    def routes
      @routes ||= ROUTES.values_at(*self.modules).compact.flatten.uniq
    end
  end
  def self.add_module(module_name, options = {})
    options.assert_valid_keys(:strategy, :model, :controller, :route, :no_input, :insert_at)

    ALL.insert (options[:insert_at] || -1), module_name

    if strategy = options[:strategy]
      strategy = (strategy == true ? module_name : strategy)
      STRATEGIES[module_name] = strategy
    end

    if controller = options[:controller]
      controller = (controller == true ? module_name : controller)
      CONTROLLERS[module_name] = controller
    end

    NO_INPUT << strategy if options[:no_input]

    if route = options[:route]
      routes = {}

      case route
      when TrueClass
        routes[module_name] = []
      when Symbol
        routes[route] = []
      when Hash
        routes = route
      else
        raise ArgumentError, ":route should be true, a Symbol or a Hash"
      end

      routes.each do |key, value|
        URL_HELPERS[key] ||= []
        URL_HELPERS[key].concat(value)
        URL_HELPERS[key].uniq!

        ROUTES[module_name] = key
      end

      if routes.size > 1
        ROUTES[module_name] = routes.keys
      end
    end

    if options[:model]
      path = (options[:model] == true ? "devise/models/#{module_name}" : options[:model])
      camelized = ActiveSupport::Inflector.camelize(module_name.to_s)
      Devise::Models.send(:autoload, camelized.to_sym, path)
    end

    Devise::Mapping.add_module module_name
  end
end
