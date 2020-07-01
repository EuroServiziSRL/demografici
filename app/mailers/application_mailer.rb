class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@soluzionipa.it'
  layout 'mailer'

  def cert_req_sent(email, nome, certificato)
    @nome = nome
    @certificato = certificato
    if !email.blank?
      mail(to: email, subject: 'Invio richiesta certificato')
    else
      logger.error "can't send email to blank email address"
    end
  end

  def cert_received_pay(email, nome, certificato)
    @nome = nome
    @certificato = certificato
    if !email.blank?
      mail(to: email, subject: 'Il tuo certificato è pronto')
    else
      logger.error "can't send email to blank email address"
    end
  end

  def cert_received_download(email, nome, certificato)
    @nome = nome
    @certificato = certificato
    if !email.blank?
      mail(to: email, subject: 'Il tuo certificato è pronto')
    else
      logger.error "can't send email to blank email address"
    end
  end

  def cert_failed(email, nome, certificato)
    @nome = nome
    @certificato = certificato
    if !email.blank?
      mail(to: email, subject: 'Errore richiesta certificato')
    else
      logger.error "can't send email to blank email address"
    end
  end

end
