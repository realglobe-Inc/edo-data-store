Rails.application.configure do
  config.middleware.use ExceptionNotification::Rack, {
    email: {
      email_prefix: "[EDO-pc Exception] ",
      sender_address: MailerSettings.exception_notification.sender_address,
      exception_recipients: MailerSettings.exception_notification.exception_recipients
    }
  }
end
