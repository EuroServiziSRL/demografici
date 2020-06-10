window.appType = "external";

import React, { useState } from 'react';
import ReactDOM from 'react-dom';

import Select from 'react-select';
import BootstrapTable from 'react-bootstrap-table-next';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faCircleNotch } from '@fortawesome/free-solid-svg-icons'

function buttonFormatter(cell,row) {
  var label = "Stampa";
  var icon = <FontAwesomeIcon icon={faPrint} />

  if (cell.indexOf("aggiungi_pagamento_pagopa")>-1) {label = "Paga con PagoPA"; icon = <FontAwesomeIcon icon={faCreditCard} />}
  else if(cell.indexOf("servizi/pagamenti")>-1) { label = "Vai al carrello"; icon = <FontAwesomeIcon icon={faShoppingCart} /> }
  return  <a href={cell} target="_blank" className="btn btn-default">{label} {icon}</a>;
} 

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

function moneyFormatter(number) {  
  if(number>0) {
    return  <span>&euro; {number.toFixed(2).replace(/\./g,",")}</span>;
  } else {
    return  <span className="text-success">gratuito</span>;
  }
} 

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

function dateFormatter(dateTimeString) {
  var formatted = "";
  if(dateTimeString) {
    var date = new Date(dateTimeString.replace(/-/g,"/").replace(/T/g," ").replace(/\.\d{3}Z/g,""));
    formatted = date.toLocaleDateString("IT");
  }
  return formatted;
}

function todo(message, type) {
  if(typeof(type)=="undefined") { type="warning"; }
  if(demograficiData.test) {
    return <span className={"ml10 alert alert-"+type}>({message})</span>
  }
}

function ucfirst(str){
  return str?str.replace(/(\b)([a-zA-Z])/,
    function(firstLetter){
      return   firstLetter.toUpperCase();
    }):"";
}

function linkAnagraficaFormatter(cell,row) {
  return  <a href={demograficiData.dominio+"/dettagli_persona?codice_fiscale="+cell}>{cell}</a>;
} 

class DemograficiForm extends React.Component{
  cols = 12
  maxLabelCols = 2
  rows = []

  constructor(props){
    super(props);
    console.log("DemograficiForm received props");
    console.log(props);
    if( typeof(props.cols) != "undefined" ) { this.cols = props.cols; }
    if( typeof(props.maxLabelCols) != "undefined" ) { this.maxLabelCols = props.maxLabelCols; }
    this.rows = props.rows
    console.log("constructor end");
  }

  render() {
    console.log("rendering DemograficiForm");
    console.log("rows");
    console.log(this.rows);
    var rowsHtml = []
    
    for(var r in this.rows) {
      var fieldsHtml = [];
      var fields = this.rows[r];
      var fieldCols = this.cols/fields.length;
      var labelCols = Math.floor(fieldCols/3);
      if(labelCols>2) { labelCols = this.maxLabelCols; } // senò è enorme dai
      var valueSize = fieldCols-labelCols;
      for(var f in fields) {
        if( typeof(fields[f].labelCols) == "undefined" ) { fields[f].labelCols = labelCols; }
        if( typeof(fields[f].valueSize) == "undefined" ) { fields[f].valueSize = valueSize; }
        if(fields[f].name!=null) {
          var labelClass = "col-lg-"+fields[f].labelCols+" control-label";
          if( typeof(fields[f].label) == "undefined" ) { fields[f].label = ucfirst(fields[f].name); }
          fieldsHtml.push(<label key={"label"+f.toString()} htmlFor={fields[f].name} className={labelClass}>{fields[f].label}</label>)
        } else {
          fields[f].valueSize = fieldCols;
        }
        var valueClass = "col-lg-"+fields[f].valueSize;
        if(fields[f].html) {
          fieldsHtml.push(<div key={"div"+f.toString()} className={valueClass} id={fields[f].name}>{fields[f].value}</div>)
        } else {
          fieldsHtml.push(<div key={"div"+f.toString()} className={valueClass}><p id={fields[f].name} className="form-control-static">{fields[f].value}</p></div>)
        }
                
      }
      rowsHtml.push(<div key={"row"+r.toString()} className="form-group"> {fieldsHtml} </div>)
    }
    return rowsHtml;
  }
}
class RicercaAnagrafiche extends React.Component{

  state = {
    token:false,
    error:false, 
    error_message:false,  
    dati: undefined,   
    loading: true,
    csrf: ""
  } 

  columns = [
    { dataField: "codiceFiscale", text: "Codice fiscale", formatter: linkAnagraficaFormatter },
    { dataField: "nome", text: "Nome" },
    { dataField: "cognome", text: "Cognome" },
    { dataField: "descrizioneCittadinanza", text: "Cittadinanza" },
    { dataField: "sesso", text: "Sesso" },
    { dataField: "dataNascita", text: "Data di nascita" },
  ];

  constructor(props){
    super(props);
    
    this.authenticate();
  }
   
  componentDidUpdate(prevProps, prevState, snapshot) {
    
    console.log("AppTributi did update");
    var canBeResponsive = true;
    if($('li.table-header').length==0) {
      $('<li class="table-header">').appendTo("body");
      canBeResponsive = typeof(tableToUl) === "function" && typeof($('li.table-header').css("font-weight"))!="undefined";
      $('li.table-header').remove();
    } 
    $("table.table-responsive").each(function(){
      var id = $(this).attr("id");
      if(canBeResponsive) {
        console.log("Calling tableToUl on "+id);
        tableToUl($("#"+id));
      } else  { console.log("tableToUl is not a function ("+typeof(tableToUl)+") or no css available for responsive tables"); } 
    });
  }

  authenticate() {
    console.log("demograficiData.dominio: "+demograficiData.dominio);
    var self = this;
    console.log("Ricerca anagrafiche - Authenticating on "+demograficiData.dominio+"/authenticate...");
    $.get(demograficiData.dominio+"/authenticate").done(function( response ) {
      console.log("response is loaded");
      console.log(response);
      var state = self.state;
      if(response.hasError) {
        state.error = true;
        state.debug = "Errore di autenticazione";
        state.loading = false;
        self.setState(state);
      } else {
        console.log("setting csrf");
        state.csrf = response.csrf;
        self.setState(state);
        self.ricercaAnagrafiche();
      }
    }).fail(function(response) {
      console.log("authentication fail!");
      console.log(response);
      var state = self.state;
      state.error = true;
      state.error_message = "Si è verificato un errore generico durante l'autenticazione";
      state.loading = false;
      self.setState(state);
    });
  } 

  ricercaAnagrafiche(e) {
    console.log(e);
    if(e){e.preventDefault();}
    var self = this;
    var state = self.state;
    state.loading = true;
    state.dati = undefined;
    self.setState(state);
    console.log("ricercaAnagrafiche...");    
    $.get(demograficiData.dominio+"/ricerca_anagrafiche_individui", $('#formRicercaAnagrafiche').serialize()).done(function( response ) {
      console.log("ricercaAnagrafiche response is loaded");
      console.log(response);
      if(response.hasError) {
        console.log("response error");
      } else {
        state = self.state;
        state.error = false;
        state.debug = response;
        if(!response.errore) {
          state.dati = response.data;
          state.debug = response;
        } else {
          state.error = true;
          state.error_message = response.messaggio_errore;
        }
        state.loading = false;
        self.setState(state);
        console.log("state.dati");
        console.log(self.state.dati);
      }
    }).fail(function(response) {
      console.log("ricercaAnagrafiche fail!");
      console.log(response);
      var state = self.state;
      state.error = true;
      state.error_message = "Si è verificato un errore generico durante l'interrogazione dati.";
      state.loading = false;
      self.setState(state);
    });
  }

  render() {
    console.log("rendering");
    var content = <div>
      {this.state.csrf=="" ? <div className="alert alert-info">Caricamento...</div> : <form method="post" action="" className="form-ricerca form-horizontal panel panel-default col-lg-12 col-md-12 col-sm-12 col-xs-12" onSubmit={this.ricercaAnagrafiche.bind(this)} id="formRicercaAnagrafiche">
        <DemograficiForm rows={[
          [
            { name:"cognomeNome", label:"Cognome/Nome", value: <input type="text" className="form-control" name="cognomeNome" id="cognomeNome"/>, html: true },
          ],
          [
            { name:"codiceFiscale", label:"Codice Fiscale", value: <input type="text" className="form-control" name="codiceFiscale" id="codiceFiscale"/>, html: true },
            { name:"indirizzo", value: <input type="text" className="form-control" name="indirizzo" id="indirizzo"/>, html: true }
          ],
          [
            { name:"", value: <input type="submit" name="invia" className="btn btn-default" value="Cerca"/>, html: true },
            { name: "", value: <input type="hidden" name="authenticity_token" value={this.state.csrf}/>, html: true }
          ]
        ]}/>
      </form>}
        
      {this.state.loading ? <p className="text-center"><FontAwesomeIcon icon={faCircleNotch}  size="2x" spin /><span className="sr-only">caricamento...</span></p> : this.state.dati.length > 0 ? <div><BootstrapTable
        id="ricercaAnagrafiche"
        keyField={"codiceCittadino"}
        data={this.state.dati}
        columns={this.columns}
        classes="table-responsive"
        striped
        hover
      /></div> : <p className="text-center">Nessun risultato</p> }

      {demograficiData.test?<pre style={{"whiteSpace": "break-spaces"}}><code>{this.state.debug?JSON.stringify(this.state.debug, null, 2):""}</code></pre>:""}

    </div>
    return content;
  }
}

if(document.getElementById('app_demografici_container') !== null){
  ReactDOM.render(<RicercaAnagrafiche />, document.getElementById('app_demografici_container') );
}