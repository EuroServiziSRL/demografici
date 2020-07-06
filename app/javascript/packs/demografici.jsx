// file da includere in tutte le pagine
import React from 'react';

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faCircleNotch, faShoppingCart, faCheck, faExclamation, faFileArchive, faFilePdf } from '@fortawesome/free-solid-svg-icons'

demograficiData.dominio = window.location.protocol+"//"+window.location.hostname+(window.location.port!=""?":"+window.location.port:"");
// TODO chiedere elenco stati a giambanco
demograficiData.descrizioniStatus = {"D":"DECEDUTO", "R":"RESIDENTE", "A":"RESIDENTE AIRE", "I":"IRREPERIBILE", "E":"EMIGRATO"};
// export {demograficiData};

function buttonFormatter(cell,row) {
  var button = ""

  if (cell.indexOf("aggiungi_pagamento_pagopa")>-1 || cell.indexOf("inserisci_pagamento")>-1) { button = <span>
    <a className="btn btn-async" href={cell} title="Aggiungi al carrello"><FontAwesomeIcon icon={faShoppingCart} size='2x'/></a>
    <a className="btn hidden wait-icon" title="Attendi..."><FontAwesomeIcon icon={faCircleNotch} size='2x' spin /></a>
    <a className="btn hidden done-icon text-success" title="Pagamento aggiunto al carrello"><FontAwesomeIcon icon={faCheck} size='2x' /></a>
    <a className="btn hidden error-icon text-danger" href="#" title="Errore durante l'aggiunta del pagamento"><FontAwesomeIcon icon={faExclamation} size='2x' /></a>
  </span> }
  else if(cell.indexOf("servizi/pagamenti")>-1) { button = <span><a className="btn done-icon text-success" title="Pagamento aggiunto al carrello"><FontAwesomeIcon icon={faCheck} size='2x' /></a></span> }
  else if(cell.indexOf("scarica_certificato")>-1) { 
    var icon = <FontAwesomeIcon icon={faFilePdf} size='2x' />
    var title = "Scarica certificato pdf"
    if(cell.indexOf(".zip")>-1) {
      icon = <FontAwesomeIcon icon={faFileArchive} size='2x' />
      title = "Scarica certificato e marca da bollo digitale"
    }
    button = <span><a className="btn" href={cell} title={title}>{icon}</a></span> 
  }
  // return  <a href={cell} target="_blank" className="btn btn-default">{label} {icon}</a>;
  return button;
} 
export {buttonFormatter};

function statiFormatter(stato) {
  var type = "muted";

  if(stato == "da_pagare" ){
    type = "info";
  } else if(stato == "scaricato" ){
    type = "success";
  } else if(stato == "pagato" ){
    type = "success";
  } else if(stato=="errore"){
    type = "danger";
  } else if(stato=="non_emettibile"){
    stato = "certificato_non_emettibile";
    type = "danger";
  } else if(stato=="annullato"){
    stato=="annullata";
    type = "danger";
  } else if(stato=="in_attesa"){
    stato = "in_elaborazione";
    type = "warning";
  } else if(stato=="nuovo"){
    stato = "inviata";
  }
  
  return  <span className={"text-"+type}>{ucfirst(stato.replace(/_/g," "))}</span>;
} 
export {statiFormatter};

function moneyFormatter(number) {
  number = parseFloat(number)  
  if (typeof number.toFixed !== "function") {
    return  <span>-</span>;
  } else if(number>0) {
    return  <span>&euro; {number.toFixed(2).replace(/\./g,",")}</span>;
  } else {
    return  <span className="text-success">gratuito</span>;
  }
} 
export {moneyFormatter};

function esenzioneFormatter(idEsenzione) {  
  if(idEsenzione) {
    var esenzioneFound = false
    for(var e in demograficiData.esenzioniBollo) {
      if (demograficiData.esenzioniBollo[e].id == idEsenzione) { esenzioneFound = demograficiData.esenzioniBollo[e].descrizione; break; }
    }
    if(esenzioneFound) {
      return esenzioneFound;
    } else {
      return "";
    }
  } else {
    return "";
  }
} 
export {esenzioneFormatter};

function dateFormatter(dateTimeString) {
  var formatted = "";
  if(dateTimeString) {
    var dateString = dateTimeString.replace(/-/g,"/").replace(/T.*/g," ").replace(/\.\d{3}Z/g,"");
    var date = new Date(dateString);
    formatted = date.toLocaleDateString("IT");
  }
  return formatted;
}
export {dateFormatter};

function tipoCertFormatter(cell,row) {
  return "Certificato "+cell;
}
export {tipoCertFormatter};

function ucfirst(str){
  return str?str.replace(/(\b)([a-zA-Z])/,
    function(firstLetter){
      return   firstLetter.toUpperCase();
    }):"";
}
export {ucfirst};

function linkAnagraficaFormatter(cell) {
  return  <span dangerouslySetInnerHTML={ {__html: cell} } />
} 
export {linkAnagraficaFormatter};

function posizioneAnagraficaFormatter(cell) {
  return demograficiData.descrizioniStatus[cell]
}
export {posizioneAnagraficaFormatter};

function hash(s){
  return s.split("").reduce(function(a,b){a=((a<<5)-a)+b.charCodeAt(0);return a&a},0);              
}
export {hash};

$(document).ready(function(){
  if(!$("#ciaoUtente").length) {
    var $links = $("#topbar").find(".row");
    $links.find("div").last().remove();
    $links.find("div").first().removeClass("col-lg-offset-3").removeClass("col-md-offset-3");
    $links.append('<div class="col-lg-2 col-md-2 text-center"><a id="ciaoUtente" href="/portale" title="Sezione Privata">CIAO<br>'+$("#nome_utente").text()+'</a></div>');
    $links.append('<div class="col-lg-1 col-md-1 logout_link"><a href="logout" title="Logout"><span class="glyphicon glyphicon-log-out" aria-hidden="true"></span></a></div>');
  }
 });