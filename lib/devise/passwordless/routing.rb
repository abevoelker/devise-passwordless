module ActionDispatch::Routing
  class Mapper

    protected

      def devise_magic_link(mapping, controllers) #:nodoc:
        resource :magic_link, only: [:show],
          path: mapping.path_names[:magic_link], controller: controllers[:magic_links]
      end
  end
end
