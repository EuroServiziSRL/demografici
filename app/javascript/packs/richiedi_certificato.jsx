window.appType = "external";

import React from 'react';
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
}