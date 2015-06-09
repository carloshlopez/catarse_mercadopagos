CatarseMercadopagos::Engine.routes.draw do
  namespace :payment do
    get '/mercadopagos/:id_contribution/review' => 'mercadopagos#review', :as => 'review_mercadopagos'
    post '/mercadopagos/notifications' => 'mercadopagos#ipn',  :as => 'ipn_mercadopagos'
    get '/mercadopagos/notifications' => 'mercadopagos#ipn',  :as => 'ipn_mercadopagos_get'
    post '/mercadopagos/:id_contribution/notifications' => 'mercadopagos#notifications',  :as => 'notifications_mercadopagos'
    get '/mercadopagos/:id_conribution/notifications' => 'mercadopagos#notifications',  :as => 'notifications_mercadopagos_get'
    get '/mercadopagos/:id_contribution/success'       => 'mercadopagos#success',        :as => 'success_mercadopagos'
    get '/mercadopagos/:id_contribution/pending'       => 'mercadopagos#pending',        :as => 'pending_mercadopagos'
    get '/mercadopagos/:id_contribution/failure'       => 'mercadopagos#failure',        :as => 'failure_mercadopagos'
    post '/mercadopagos/:id_contribution/cancel'        => 'mercadopagos#cancel',         :as => 'cancel_mercadopagos'
  end
end
