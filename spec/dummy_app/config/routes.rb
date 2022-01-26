Rails.application.routes.draw do
  get '/', to: proc { [200, {}, ['<html />']] }
end
