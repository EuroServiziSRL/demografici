window.appType = "external";

import React, { useState } from 'react';
import ReactDOM from 'react-dom';

class RichiediCertificato extends React.Component{


  constructor(props){
    super(props);
  }

  render() {
    return <div><p className="alert alert-success">La tua richiesta è stata inviata</p><p className="text-center"><a href='/dettagli_persona' className="btn btn-default">Torna indietro</a></p></div>;
  }
}

if(document.getElementById('app_demografici_container') !== null){
  ReactDOM.render(<RichiediCertificato />, document.getElementById('app_demografici_container') );
  var $links = $("#topbar").find(".row");
  $links.find("div").last().remove();
  $links.find("div").first().removeClass("col-lg-offset-3").removeClass("col-md-offset-3");
  $links.append('<div class="col-lg-2 col-md-2 text-center"><a href="/portale" title="Sezione Privata">CIAO<br>'+$("#nome_utente").text()+'</a></div>');
  $links.append('<div class="col-lg-1 col-md-1 logout_link"><a href="logout" title="Logout"><span class="glyphicon glyphicon-log-out" aria-hidden="true"></span></a></div>');
}