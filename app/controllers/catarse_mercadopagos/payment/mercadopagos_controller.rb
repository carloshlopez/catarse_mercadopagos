# encoding: utf-8
require 'mercadopago.rb'
module CatarseMercadopagos::Payment
  class MercadopagosController < ApplicationController
    skip_before_filter :verify_authenticity_token, :only => [:notifications]
    skip_before_filter :detect_locale, :only => [:notifications]
    skip_before_filter :set_locale, :only => [:notifications]
    skip_before_filter :force_http
    
    before_filter :setup_gateway
    
    SCOPE = "projects.contributions.checkout"

    layout :false

    def review
      begin
        # contribution = current_user.backs.not_confirmed.find params[:id]
        contribution = ::Contribution.find(params[:id])
        # Just to render the review form
       # @preference = generate_normal_payment_link
       @preference = generate_checkout_payment_link contribution
       puts "$%$%$ Preference created #{@preference.inspect}"
      rescue Exception => e
        puts "Error en review ####$$$$$$$$$$$$ %%%%   #{e.inspect}"
      end

    end

    def success
      begin
        contribution = ::Contribution.find(params[:id])
        preference = @@gateway.get_preference(params[:preference_id])
        puts "si existe la preference aquí esta #{preference}"
        if params[:collection_status] == "approved"
          contribution.update_attribute :payment_method, 'Mercadopagos'
          contribution.update_attribute :payment_token, params[:preference_id]

          proccess!(contribution, preference, "success")
          mercadopagos_flash_success

          redirect_to main_app.project_contribution_path(project_id: contribution.project.id, id: contribution.id)
        else
          puts "*******Ocurrió un error no es un succes"
          mercadopagos_flash_error
          return redirect_to main_app.new_project_contribution_path(contribution.project)
        end
      rescue Exception => e
        puts "--*******************success page error-----> #{e.inspect}"
        mercadopagos_flash_error
        return redirect_to main_app.new_project_contribution_path(contribution.project)
      end
    end

    def pending
      begin
        contribution = ::Contribution.find(params[:id])
        preference = @@gateway.get_preference(params[:preference_id])
        puts "si existe la preference aquí esta #{preference}"
        if params[:collection_status] == "pending"
          contribution.update_attribute :payment_method, 'Mercadopagos'
          contribution.update_attribute :payment_token, params[:preference_id]

          proccess!(contribution, preference, "pending")
          mercadopagos_error "La transacción no pudo ser confirmada con Mercadopagos"
          redirect_to main_app.new_project_contribution_path(contribution.project)
        elsif params[:collection_status] == "in_process"
          contribution.update_attribute :payment_method, 'Mercadopagos'
          contribution.update_attribute :payment_token, params[:preference_id]

          proccess!(contribution, preference, "waiting")
          mercadopagos_error "La transacción no pudo ser confirmada con Mercadopagos, se encuentra pendiente."
          redirect_to main_app.new_project_contribution_path(contribution.project)
        else
          puts "*******Ocurrió un error no es un succes"
          mercadopagos_flash_error
          return redirect_to main_app.new_project_contribution_path(contribution.project)
        end
      rescue Exception => e
        puts "--*******************pending page error-----> #{e.inspect}"
        mercadopagos_flash_error
        return redirect_to main_app.new_project_contribution_path(contribution.project)
      end
    end

    def failure
      begin
        contribution = ::Contribution.find(params[:id])
        preference = @@gateway.get_preference(params[:preference_id])
        puts "si existe la preference aquí esta #{preference}"
        if params[:collection_status] == "failure"
          contribution.update_attribute :payment_method, 'Mercadopagos'
          contribution.update_attribute :payment_token, params[:preference_id]

          proccess!(contribution, preference, "failure")
          mercadopagos_error "La transacción CANCELADA por Mercadopagos"
          redirect_to main_app.new_project_contribution_path(contribution.project)
        elsif params[:collection_status] == "in_process"
          contribution.update_attribute :payment_method, 'Mercadopagos'
          contribution.update_attribute :payment_token, params[:preference_id]

          proccess!(contribution, preference, "waiting")
          mercadopagos_error "La transacción no pudo ser confirmada con Mercadopagos, se encuentra pendiente."
          redirect_to main_app.new_project_contribution_path(contribution.project)
        else
          puts "*******Ocurrió un error no es un succes"
          mercadopagos_flash_error
          return redirect_to main_app.new_project_contribution_path(contribution.project)  
        end
      rescue Exception => e
        puts "--*******************failure page error-----> #{e.inspect}"
        mercadopagos_flash_error
        return redirect_to main_app.new_project_contribution_path(contribution.project)
      end
    end

    def notifications
      begin
        # contribution = current_user.backs.find params[:id]
        contribution = ::Contribution.find(params[:id_conribution])

        # filters = Array["id"=>params[:id].to_i, "site_id"=>"MCO"]
        # searchResult = @@gateway.search_payment(filters)
        resp = @@gateway.get("/collections/#{params[:id]}", nil, true)
         puts "Resultados de buscar en mercadopagos #{resp.inspect} "
        if resp["response"]["status"] == "approved"
          puts "******* FUE EXITOSO VAMOS A PROCESAR CON SUCCESS :)"
          proccess!(contribution, resp, "success")
          render status: 200, nothing: true
        elsif resp["status"] == "rejected" or resp["status"] == "cancelled"
          puts "******* FUE FALLIDO VAMOS A PROCESAR CON FAILURE :)"
          proccess!(contribution, resp, "failure")
          render status: 200, nothing: true
        elsif resp["status"] == "pending"
          puts "******* FUE PENDING VAMOS A PROCESAR CON PENDING :)"
          proccess!(contribution, resp, "pending")
          render status: 200, nothing: true
        elsif resp["status"] == "in_process"
          puts "******* FUE INCIERTO VAMOS A PROCESAR CON WAITING :)"
          proccess!(contribution, resp, "waiting")
          render status: 200, nothing: true
        else
          puts "************ NO entendemos el mensaje"
          render status: 404, nothing: true
        end
      rescue Exception => e
        puts "Error --notifications error-----> #{e.inspect}"
        render status: 404, nothing: true
      end
    end

    def ipn
        # contribution = current_user.backs.find params[:id]
        contribution = ::Contribution.find(params[:id_conribution])

        # filters = Array["id"=>params[:id].to_i, "site_id"=>"MCO"]
        # searchResult = @@gateway.search_payment(filters)
        puts "PARAMS #{params.inspect}"
        resp = @@gateway.get("/collections/#{params[:id]}", nil, true)
        puts "Resultados de buscar en mercadopagos #{resp.inspect} "
    end

    protected

    def proccess!(contribution, resp, status)
      begin
        notification = contribution.payment_notifications.new({
          extra_data: resp
        })
      rescue Exception => e
        puts "Error en enviar la notificación!! #{e.inspect}"
      end

  # TODO falta hacer algo con todos estos estados
  # status  Estado del pago
  # pending El usuario no completó el proceso de pago.
  # approved  El pago fue aprobado y acreditado.
  # in_process  El pago está siendo revisado.
  # rejected  El pago fue rechazado. El usuario puede intentar nuevamente.
  # cancelled El pago fue cancelado por superar el tiempo necesario para realizar el pago o por una de las partes.
  # refunded  El pago fue devuelto al usuario.
  # in_mediation  Se inició una disputa para el pago.
  # charged_back  Se realizó un contracargo en la tarjeta de crédito.
        if status == "success"
          puts "***********ES UN SUCCESS"
          contribution.confirm!
        elsif status == "failure"
          puts "*********** ES UN FAILURE"
          contribution.cancel!
        elsif status == "pending"
          puts "******** ES UN PENDING"
          contribution.pending!
        elsif status == "waiting"
          puts "******** ES UN WAITING"
          contribution.waiting!
        end
    end

    def mercadopagos_error(error_message)
      flash[:failure] = t('mercadopagos_error', scope: SCOPE) << error_message
    end
    
    def mercadopagos_flash_error
      flash[:failure] = t('mercadopagos_error', scope: SCOPE)
    end

    def mercadopagos_flash_success
      flash[:success] = t('success', scope: SCOPE)
    end

    def setup_gateway
      begin
        # if ::Configuration[:mercadopagos_client_id] and ::Configuration[:mercadopagos_client_secret]
          @@gateway = MercadoPago.new(::Configuration[:mercadopagos_client_id] , ::Configuration[:mercadopagos_client_secret] )


        # else
        #   raise "*****!!!!!!!!!!! [Mercadopagos] mercadopagos_client_id and mercadopagos_client_secret are required to make requests to Mercadopagos"
        # end
      rescue Exception => e
        puts "*******!!!!!!!!!!!! Algo pasó malo al crear el @@gateway de mercadopagos !!! #{e.inspect}"
      end
    end

    def generate_normal_payment_link
      puts "&&&&&&&&&&&&&************!!!!!!! #{@@gateway.inspect}"
      accessToken = @@gateway.get_access_token()
      puts "accessToken = #{accessToken}"
       preferenceData = Hash["items" =>
          Array(
            Array["id"=>"sumame-proyect-#{contribution.project.id}-contribution-#{contribution.id}-user-#{current_user.id}",
           "title"=>"Aporte a la campaña #{contribution.project.name} por #{contribution.value}",
           "quantity"=>1,
           "description" => "Esta transacción es por el aporte de #{current_user.name} a la campaña #{contribution.project.name} por un valor de #{contribution.value}",
           "unit_price"=> contribution.value.to_f,
           "currency_id"=>"COP"]),
          "payer" =>{"name" => "CONT#{current_user.name}",
                "surname" => "CONT#{current_user.full_name}",
                "email" => "#{current_user.email}"},
          "back_urls" => {"success"=>"#{payment_success_mercadopagos_url(id: contribution.id)}",
                          "pending"=>"#{payment_pending_mercadopagos_url(id: contribution.id)}",
                          "failure"=>"#{payment_failure_mercadopagos_url(id: contribution.id)}"
                         },
          "notification_url" => "#{payment_notifications_mercadopagos_url(id_conribution: contribution.id)}"
          ]
        @@gateway.create_preference(preferenceData)

    end

    def generate_checkout_payment_link (contribution)
      mpc = ::MercadoPagoClient.find_by_project_id(contribution.project.id)
      # params = "grant_type=refresh_token&client_id=#{::Configuration[:mercadopagos_client_id]}&client_secret=#{::Configuration[:mercadopagos_client_secret]}&refresh_token=#{mpc.refresh_token}"
      params = Hash["grant_type" => "refresh_token",
        "client_id" => "#{Configuration[:mercadopagos_client_id]}",
        "client_secret" => "#{Configuration[:mercadopagos_client_secret]}",
        "refresh_token"=> "#{mpc.refresh_token}"]
      resp = @@gateway.post("/oauth/token", params)
      puts "%$%$ Respuesta es #{resp.inspect}"
      mpc.access_token = resp['response']['access_token']
      mpc.refresh_token = resp['response']['refresh_token']
      mpc.save!
       preferenceData = Hash["items" =>
          Array(
            Array["id"=>"sumame-proyect-#{contribution.project.id}-contribution-#{contribution.id}-user-#{current_user.id}",
           "title"=>"Aporte a la campaña #{contribution.project.name} por #{contribution.value}",
           "quantity"=>1,
           "description" => "Esta transacción es por el aporte de #{current_user.name} a la campaña #{contribution.project.name} por un valor de #{contribution.value}",
           "unit_price"=> contribution.value.to_f,
           "currency_id"=>"COP"]),
          "payer" =>{"name" => "CONT#{current_user.name}",
                "surname" => "CONT#{current_user.full_name}",
                "email" => "#{current_user.email}"
                },
          "back_urls" => {"success"=>"#{payment_success_mercadopagos_url(id: contribution.id)}",
                          "pending"=>"#{payment_pending_mercadopagos_url(id: contribution.id)}",
                          "failure"=>"#{payment_failure_mercadopagos_url(id: contribution.id)}"
                         },
          "notification_url" => "#{payment_notifications_mercadopagos_url(id_conribution: contribution.id)}",
          "marketplace_fee" => "#{contribution.value.to_f * ::Configuration[:catarse_fee]}"
          ]
        # mp = MercadoPago.new(mpc.access_token)
        @@gateway.create_preference(preferenceData)


    end

  end
end