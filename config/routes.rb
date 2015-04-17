CatarseMercadopagos::Engine.routes.draw do
  namespace :payment do
    get '/mercadopagos/:id/review' => 'mercadopagos#review', :as => 'review_mercadopagos'
    post '/mercadopagos/notifications' => 'mercadopagos#ipn',  :as => 'ipn_mercadopagos'
    post '/mercadopagos/:id/notifications' => 'mercadopagos#notifications',  :as => 'notifications_mercadopagos'
    get '/mercadopagos/:id/success'       => 'mercadopagos#success',        :as => 'success_mercadopagos'
    post '/mercadopagos/:id/cancel'        => 'mercadopagos#cancel',         :as => 'cancel_mercadopagos'
  end
end
