window.appType = "external";

import React, { useState } from 'react';
import ReactDOM from 'react-dom';

var dominio = window.location.protocol+"//"+window.location.hostname+(window.location.port!=""?":"+window.location.port:"");

class RichiediCertificato extends React.Component{


  constructor(props){
    super(props);
  }

  render() {
    return <div><p className="alert alert-success">La tua richiesta è stata inviata</p><p className="text-center"><a href='#' className="btn btn-default history-back">Torna indietro</a></p></div>;
  }
}

if(document.getElementById('app_demografici_container') !== null){
  ReactDOM.render(<RichiediCertificato />, document.getElementById('app_demografici_container') );

  $('#portal_container').on('click', '.history-back', function(e){
    e.preventDefault();
    history.back();
  });
}