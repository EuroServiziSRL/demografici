class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@soluzionipa.it'
  layout 'mailer'

  def cert_req_sent(email, nome)
    @nome = nome
    if !email.blank?
      mail(to: email, subject: 'Invio richiesta certificato')
    else
      logger.error "can't send email to blank email address"
    end
  end

  def cert_received_pay(email, nome)
    @nome = nome
    if !email.blank?
      mail(to: email, subject: 'Il tuo certificato è pronto')
    else
      logger.error "can't send email to blank email address"
    end
  end

  def cert_received_download(email, nome)
    @nome = nome
    if !email.blank?
      mail(to: email, subject: 'Il tuo certificato è pronto')
    else
      logger.error "can't send email to blank email address"
    end
  end

end
