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
          "notification_url" => "#{payment_notifications_mercadopagos_url(id: contribution.id)}"
          ]
        @preference = @@gateway.create_preference(preferenceData)
      rescue Exception => e
        puts "####$$$$$$$$$$$$ %%%%   #{e.inspect}"
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
      # contribution = current_user.backs.find params[:id]
      contribution = ::Contribution.find(params[:id])

      filters = Array["id"=>params[:preference_id], "site_id"=>"MCO"]
      searchResult = @@gateway.search_payment(filters)

       puts "Resultados de buscar en mercadopagos #{searchResult.inspect} "
      if response.valid?
        puts "******* VAMOS A VALIDAR :)"
        proccess!(contribution, response)
        render status: 200, nothing: true
      else
        puts "************ NO ES VALIDA LA FIRMA"
        datos = [response.client.key,response.client.account_id, response.reference,("%.2f" % response.amount), response.currency, response.state_code].join("~")
        signa = Digest::MD5.hexdigest(datos)


        puts "*******valores del response: #{params[:firma].upcase} debe ser igual a #{signa.upcase} que sale de firmar #{datos}"

        render status: 404, nothing: true
      end
    rescue Exception => e
      Rails.logger.info "--notifications error-----> #{e.inspect}"
      render status: 404, nothing: true
    end

    protected

    def proccess!(contribution, response, status)
      begin
        notification = contribution.payment_notifications.new({
          extra_data: response
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
        else status == "failure"
          puts "*********** ES UN FAILURE"
          contribution.cancel!
        elsif status == "pending"
          puts "******** ES UN PENDING"
          contribution.pendent!
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
        if ::Configuration[:mercadopagos_client_id] and ::Configuration[:mercadopagos_client_secret]
          @@gateway = MercadoPago.new('5726113656322623', '6CkDZgCAIRrtlUMRS7JkQoK6O9QoXAsG')
          puts "&&&&&&&&&&&&&************!!!!!!! #{@@gateway.inspect}"
          accessToken = @@gateway.get_access_token()
          puts "accessToken = #{accessToken}"

        else
          raise "*****!!!!!!!!!!! [Mercadopagos] mercadopagos_client_id and mercadopagos_client_secret are required to make requests to Mercadopagos"
        end
      rescue Exception => e
        puts "*******!!!!!!!!!!!! Algo pasó malo al crear el @@gateway de mercadopagos !!! #{e.inspect}"
      end
    end

  end
end