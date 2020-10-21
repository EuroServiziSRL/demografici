class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@soluzionipa.it'
  layout 'mailer'

  # la richiesta di certificato è stata ricevuta dal sistema
  def cert_req_sent(email, richiedente_nome, codice_fiscale, certificato)
    @nome = richiedente_nome
    @certificato = certificato
    @intestatario = !codice_fiscale.nil? ? " per "+codice_fiscale : ""
    if !email.blank?
      mail(to: email, subject: 'Richiesta certificato inviata')
    else
      logger.error "can't send email to blank email address"
    end
  end

  # il certificato è arrivato ed è disponibile per il download
  def cert_available(email, richiedente_nome, codice_fiscale, data_prenotazione, certificato, da_pagare)
    @data_prenotazione = data_prenotazione.strftime("%d/%m/%Y")
    @nome = richiedente_nome
    @certificato = certificato
    @intestatario = !codice_fiscale.nil? ? " per "+codice_fiscale : ""
    avviso_pagamento = "Il certificato è disponibile e deve ora essere  effettuato il pagamento della marca da bollo digitale o dei diritti di segreteria direttamente dal sistema, per poter effettuare il download del documento.";
    @pagamento_txt = da_pagare ? "
    
    "+avviso_pagamento : "";
    @pagamento_html = da_pagare ? "<p>"+avviso_pagamento+"</p>" : "";

    if !email.blank?
      mail(to: email, subject: 'Il tuo certificato è disponibile')
    else
      logger.error "can't send email to blank email address"
    end
  end

  # la ricezione del certificato è fallita
  def cert_failed(email, richiedente_nome, codice_fiscale, certificato)
    @nome = richiedente_nome
    @certificato = certificato
    @intestatario = !codice_fiscale.nil? ? " per "+codice_fiscale : ""
    if !email.blank?
      mail(to: email, subject: 'Errore richiesta certificato')
    else
      logger.error "can't send email to blank email address"
    end
  end

end
