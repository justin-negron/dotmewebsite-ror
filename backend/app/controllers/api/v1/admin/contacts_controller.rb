module Api
  module V1
    module Admin
      class ContactsController < BaseController
        before_action :set_contact, only: [:show, :update, :destroy]
        rescue_from ArgumentError, with: :bad_enum_value

        def index
          contacts = Contact.recent
          contacts = contacts.where(status: params[:status]) if params[:status].present?
          contacts = contacts.page(params[:page]).per(params[:per_page] || 20)
          render_success(ContactResource.new(contacts).to_h, meta: pagination_meta(contacts))
        end

        def show
          render_success(ContactResource.new(@contact).to_h)
        end

        def update
          @contact.update!(contact_params)
          render_success(ContactResource.new(@contact).to_h)
        end

        def destroy
          @contact.destroy!
          render_success({ message: 'Contact deleted' })
        end

        private

        def set_contact
          @contact = Contact.find(params[:id])
        end

        def contact_params
          params.require(:contact).permit(:status)
        end

        def bad_enum_value(exception)
          render_error(exception.message, status: :bad_request)
        end
      end
    end
  end
end
