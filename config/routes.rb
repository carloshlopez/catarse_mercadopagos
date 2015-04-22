CatarseMercadopagos::Engine.routes.draw do
  namespace :payment do
    get '/mercadopagos/:id/review' => 'mercadopagos#review', :as => 'review_mercadopagos'
    post '/mercadopagos/notifications' => 'mercadopagos#ipn',  :as => 'ipn_mercadopagos'
    post '/mercadopagos/:id/notifications' => 'mercadopagos#notifications',  :as => 'notifications_mercadopagos'
    get '/mercadopagos/:id_conribution/notifications' => 'mercadopagos#notifications',  :as => 'notifications_mercadopagos_get'
    get '/mercadopagos/:id/success'       => 'mercadopagos#success',        :as => 'success_mercadopagos'
    get '/mercadopagos/:id/pending'       => 'mercadopagos#pending',        :as => 'pending_mercadopagos'
    get '/mercadopagos/:id/failure'       => 'mercadopagos#failure',        :as => 'failure_mercadopagos'
    post '/mercadopagos/:id/cancel'        => 'mercadopagos#cancel',         :as => 'cancel_mercadopagos'
  end
end
