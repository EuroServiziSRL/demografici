window.appType = "external";

import React from 'react';
import ReactDOM from 'react-dom';

class RichiediCertificato extends React.Component{

  constructor(props){
    super(props);
  }

  render() {
    return <div><p className="alert alert-success">La tua richiesta è stata inviata.<br/>L'emissione del certificato potrebbe richiedere qualche minuto. Riceverai una mail non appena sar&agrave; disponibile.<br/>Per visualizzare in tempo reale lo stato della richiesta nonch&egrave; scaricare il certificato quando disponibile, puoi ricaricare la pagina dove hai eseguito la richiesta.</p><p className="text-center"><a href='/dettagli_persona' className="btn btn-default">Torna indietro</a></p></div>;
  }
}

if(document.getElementById('app_demografici_container') !== null){
  ReactDOM.render(<RichiediCertificato />, document.getElementById('app_demografici_container') );
}

$(document).ready(function(){
  if($(".header_nuova").length>0) {
    $("#portal_container").css("margin-top","225px");
  }
});