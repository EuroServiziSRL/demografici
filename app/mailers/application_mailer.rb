class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@soluzionipa.it'
  layout 'mailer'

  def cert_req_sent(email)
    mail(to: email, subject: 'Invio richiesta certificato')
  end

  def cert_received_pay(email)
    mail(to: email, subject: 'Il tuo certificato è pronto')
  end

  def cert_received_download(email)
    mail(to: email, subject: 'Il tuo certificato è pronto')
  end

end
