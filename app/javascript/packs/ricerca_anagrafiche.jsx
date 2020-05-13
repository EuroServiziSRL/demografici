window.appType = "external";

import React, { useState } from 'react';
import ReactDOM from 'react-dom';

import Select from 'react-select';
import BootstrapTable from 'react-bootstrap-table-next';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faCircleNotch } from '@fortawesome/free-solid-svg-icons'

var dominio = window.location.protocol+"//"+window.location.hostname+(window.location.port!=""?":"+window.location.port:"");

class RicercaAnagrafiche extends React.Component{


  constructor(props){
    super(props);
  }

  render() {
    return <div></div>;
  }
}

if(document.getElementById('app_demografici_container') !== null){
  ReactDOM.render(<RicercaAnagrafiche />, document.getElementById('app_demografici_container') );
}