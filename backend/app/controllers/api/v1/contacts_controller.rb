module Api
  module V1
    class ContactsController < BaseController
      def create
        @contact = Contact.new(contact_params)
        
        if @contact.save
          # TODO: Send email notification (we'll implement this in Step 8)
          # EmailNotificationJob.perform_later(@contact.id)
          
          render_success(
            { message: 'Thank you for your message! I will get back to you soon :)' },
            status: :created
          )
        else
          render_error(
            'Failed to send message',
            errors: @contact.errors.full_messages
          )
        end
      end
      
      private
      
      def contact_params
        params.require(:contact).permit(:name, :email, :subject, :message)
      end
    end
  end
end