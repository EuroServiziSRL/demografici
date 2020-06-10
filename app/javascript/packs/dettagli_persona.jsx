window.appType = "external";

import React, { useState } from 'react';
import ReactDOM from 'react-dom';
// import $ from 'jquery';
// window.jQuery = $;
// window.$ = $;

import Select from 'react-select';
import BootstrapTable from 'react-bootstrap-table-next';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faCircleNotch, faShoppingCart, faPrint, faCheck, faCross, faExclamation } from '@fortawesome/free-solid-svg-icons'

demograficiData.descrizioniStatus = {"D":"DECEDUTO", "R":"RESIDENTE", "A":"RESIDENTE AIRE", "I":"IRREPERIBILE", "E":"EMIGRATO"}

function buttonFormatter(cell,row) {
  var button = ""

  if (cell.indexOf("aggiungi_pagamento_pagopa")>-1 || cell.indexOf("inserisci_pagamento")>-1) { button = <span>
    <a className="btn-async" href={cell} title="Aggiungi al carrello"><FontAwesomeIcon icon={faShoppingCart} /></a>
    <FontAwesomeIcon className="hidden wait-icon" icon={faCircleNotch} spin />
    <FontAwesomeIcon className="hidden done-icon text-success" icon={faCheck} />
    <a href=""><FontAwesomeIcon className="hidden error-icon text-danger" icon={faExclamation} /></a>
  </span> }
  else if(cell.indexOf("servizi/pagamenti")>-1) { button = <span><FontAwesomeIcon className="text-success" icon={faCheck} /></span> }
  else if(cell.indexOf("scarica_certificato")>-1) { button = <a href={cell} className="btn" title="Stampa"><FontAwesomeIcon icon={faPrint} /></a> }
  // return  <a href={cell} target="_blank" className="btn btn-default">{label} {icon}</a>;
  return button;
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
  number = parseFloat(number)  
  if (typeof number.toFixed !== "function") {
    return  <span>-</span>;
  } else if(number>0) {
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
    var dateString = dateTimeString.replace(/-/g,"/").replace(/T.*/g," ").replace(/\.\d{3}Z/g,"");
    var date = new Date(dateString);
    formatted = date.toLocaleDateString("IT");
  }
  return formatted;
}

function tipoCertFormatter(cell,row) {
  return "Certificato "+cell;
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
      if(labelCols>this.maxLabelCols) { labelCols = this.maxLabelCols; } // senò è enorme dai
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
class DemograficiList extends React.Component{
  list = []
  linked = false

  constructor(props){
    super(props);
    console.log("DemograficiList received props");
    console.log(props);
    this.list = props.list;
    this.linked = props.linked;
    console.log("constructor end");
  }

  render() {
    console.log("rendering DemograficiList");
    console.log("list");
    console.log(this.list);
    console.log("linked");
    console.log(this.linked);
    var listItems = [];
    var html;
    if(this.list && this.list[0]) {
      if(this.linked) {
        listItems.push(this.list.map((item, index) => <a className="list-group-item" key={index.toString()} href={item.url}>{item.preText?<span>{item.preText}</span> :""}{item.text}{item.postText? <span className="badge">{item.postText}</span>:""}</a>  ));
      } else {
        listItems.push(this.list.map((item, index) => <li className="list-group-item" key={index.toString()}>{item.preText?<span>{item.preText}</span> :""}<a href={item.url}>{item.text}{item.postText? <span className="badge">{item.postText}</span>:""}</a></li>  ));
      }
    }
    if(this.linked) {
      html = <div className="list-group">{listItems}</div>
    } else {
      html = <ul className="list-group">{listItems}</ul>
    }
    console.log(html);
    return(html);
  }
}

class DettagliPersona extends React.Component{
  tabs= {
    "scheda_anagrafica":[],
    "decesso":[],
    "matrimonio":[],
    "divorzio":[],
    "vedovanza":[],
    "unione_civile":[],
    "scioglimento_unione_civile":[], // TODO aggiungere dentro divorzio?
    "elettorale":[],
    "documenti":[],
    "famiglia":[],
    "autocertificazioni":[],
    "certificati":[],
    // "richiedi_certificato":[],
  }

  state = {
    token:false,
    error:false, 
    error_message:false,  
    dati:{},   
    datiCittadino: [],
    loading: true
  } 

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
    console.log("Dettagli persona - Authenticating on "+demograficiData.dominio+"/authenticate...");
    // TODO gestire caso login errato su microsoft per accesso api
    $.get(demograficiData.dominio+"/authenticate").done(function( response ) {
      console.log("response is loaded");
      console.log(response);
      if(response.hasError) {
        var state = self.state;
        state.error = true;
        state.debug = "Errore di autenticazione";
        state.loading = false;
        self.setState(state);
      } else {
        self.ricercaIndividui();
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

  ricercaIndividui() {
    this.state.loading = true;
    for(var tabName in this.tabs) {
      this.state.dati[tabName] = [];
    }
    var self = this;
    console.log("ricercaIndividui...");
    $.get(demograficiData.dominio+"/ricerca_individui", {}).done(function( response ) {
      console.log("ricercaIndividui response is loaded");
      console.log(response);
      if(response == null) {
        console.log("response is null");
      }
      else if(response.length && response.hasError) {
        console.log("response error");
      } else {
        var state = self.state;
        state.error = false;
        state.debug = response;
        if(!response.errore) {
          response = self.formatData(response);
          state.dati = response.dati;
          state.datiCittadino = response.datiCittadino;
          state.datiRichiedente = response.datiRichiedente;
        } else {
          state.error = true;
          state.error_message = response.messaggio_errore;
        }
        state.loading = false;
        self.setState(state);
      }
    }).fail(function(response) {
      console.log("ricercaIndividui fail!");
      console.log(response);
      var state = self.state;
      state.error = true;
      state.error_message = "Si è verificato un errore generico durante l'interrogazione dati.";
      state.loading = false;
      self.setState(state);
    });
  }

  certRequestType() {
    $("#esenzioneBollo").parent().parent().toggle($("#bollo").is(":checked"));
  }

  formatData(datiAnagrafica) {
    var nominativo = datiAnagrafica.cognome+" "+datiAnagrafica.nome;
    var result = {"dati":{}};
    result.datiCittadino = [[
        { name: "nominativo", value: nominativo },
        { name: "indirizzo", value: datiAnagrafica.indirizzo },
      ], [
        // TODO chiedere elenco stati a giambanco
        { name: "status", value: demograficiData.descrizioniStatus[datiAnagrafica.posizioneAnagrafica] },
        { name: "codiceCittadino", label: "Numero individuale", value: datiAnagrafica.codiceCittadino },
      ]
    ];
    result.dati.scheda_anagrafica = [[
        { name: "cognome", value: datiAnagrafica.cognome },
        { name: "nome", value: datiAnagrafica.nome },
        { name: "sesso", value: datiAnagrafica.sesso },
      ], [
        { name: "codiceFiscale", label: "Codice Fiscale", value: datiAnagrafica.codiceFiscale },
        { name: "dataNascita", label: "Data di nascita", value: datiAnagrafica.dataNascita },
        { name: "comuneNascitaDescrizione", label: "Comune di nascita", value: datiAnagrafica.comuneNascitaDescrizione }, 
      ], [
        { name: "indirizzo", label: "Via di residenza", value: datiAnagrafica.indirizzo },
        { name: "descrizioneCittadinanza", label: "Cittadinanza", value: datiAnagrafica.descrizioneCittadinanza },
        { name: "statoCivile", label: "Stato civile", value: datiAnagrafica.datiStatoCivile?datiAnagrafica.datiStatoCivile.statoCivile:"" },
      ], [
        { name: "titoloStudio", label: "Titolo studio", value: datiAnagrafica.datiTitoloStudio!=null?datiAnagrafica.datiTitoloStudio.descrizione:"" },
        { name: "professione", label: "Professione", value: datiAnagrafica.datiProfessione!=null?datiAnagrafica.datiProfessione.descrizione:"" },
        { name: "", value: "" },
      ]
    ];

    result.dati.documenti = [];

    // if(demograficiData.test) {
    //   result.dati.documenti.push([
    //     { name: "numero", value: documento.numero },
    //     { name: "stato", value: todo("manca l'informazione","danger") },
    //     { name: "dataRilascio", label: "In data", value: dateFormatter(documento.dataRilascio) },
    //     { name: "scadenza", value: todo("manca l'informazione","danger") },
    //   ]);
    // }

    if(datiAnagrafica.datiCartaIdentita!=null) {
      var documento = datiAnagrafica.datiCartaIdentita;
      var rilasciataDa = "";
      if(documento.comuneRilascio) { rilasciataDa = "Comune di "+documento.comuneRilascio; }
      else if(documento.consolatoRilascio) { rilasciataDa = "Comune di "+documento.consolatoRilascio; }
      result.dati.documenti.push([
        { name: "tipoDocumento", label: "Tipo", value: "Carta d'identit&agrave;" },
        { name: "numero", value: documento.numero },
        { name: "comuneRilascio", label: "Rilasciata da", value: rilasciataDa },
        // { name: "stato", value: todo("manca l'informazione","danger") },
        { name: "dataRilascio", label: "In data", value: dateFormatter(documento.dataRilascio) },
        // { name: "scadenza", value: todo("manca l'informazione","danger") },
      ]);
    }

    if(datiAnagrafica.datiTitoloSoggiorno!=null) {
      var documento = datiAnagrafica.datiTitoloSoggiorno;
      var rilasciataDa = "";
      if(documento.comuneRilascio) { rilasciataDa = "Comune di "+documento.comuneRilascio; }
      else if(documento.consolatoRilascio) { rilasciataDa = "Consolato di "+documento.consolatoRilascio; }
      else if(documento.questuraRilascio) { rilasciataDa = "Questura di "+documento.questuraRilascio; }
      result.dati.scheda_anagrafica.push([
        { name: "titoloSoggiorno", label: "Titolo di soggiorno", value: documento.tipo },
        { name: "numero", value: documento.numero },
        { name: "comuneRilascio", label: "Rilasciato da", value: rilasciataDa },
        { name: "dataRilascio", label: "In data", value: dateFormatter(documento.dataRilascio) },
      ]);
    }

    if(datiAnagrafica.datiVeicoli && datiAnagrafica.datiVeicoli.length) {
      var documento = datiAnagrafica.datiVeicoli;
      result.dati.documenti.push([
        { name: "possessoVeicoli", label: "Possesso veicoli", value: documento.possesso },
        { name: "", value: "" },
        { name: "", value: "" },
        { name: "", value: "" },
      ]);
    }

    if(datiAnagrafica.datiPatente && datiAnagrafica.datiPatente.length) {
      var documento = datiAnagrafica.datiPatente;
      result.dati.documenti.push([
        { name: "possessoPatente", label: "Possesso patente", value: documento.possesso },
        { name: "", value: "" },
        { name: "", value: "" },
        { name: "", value: "" },
      ]);
    }

    result.dati.famiglia = []
    if(datiAnagrafica.famiglia) {
      var famigliaFormatted = false;
      if(datiAnagrafica.famiglia){
        famigliaFormatted = []
        for (var componente in datiAnagrafica.famiglia) {
          famigliaFormatted.push({
            preText: null,
            text: datiAnagrafica.famiglia[componente].cognome+" "+datiAnagrafica.famiglia[componente].nome+" ("+datiAnagrafica.famiglia[componente].sesso+") -  "+datiAnagrafica.famiglia[componente].dataNascita,
            postText: datiAnagrafica.famiglia[componente].relazioneParentela,
            url: demograficiData.dominio+"/dettagli_persona?codice_fiscale="+datiAnagrafica.famiglia[componente].codiceFiscale
          });
        }
      }
      console.log(famigliaFormatted);
      result.dati.famiglia = [[
          { name: "codiceFamiglia", label: "Famiglia N.", value: datiAnagrafica.codiceFamiglia },
          { name: "numeroComponenti", label: "Numero componenti", value: datiAnagrafica.famiglia?datiAnagrafica.famiglia.length:1 },
        ],[
          { name: "componenti", value: <DemograficiList list={famigliaFormatted} linked="true"/>, html: true },
          { name: "", value: "" },
        ]
      ];
    }
    
    result.dati.decesso = [];
    if(datiAnagrafica.datiDecesso) {
      var datiDecesso = datiAnagrafica.datiDecesso;
      result.dati.decesso.push([
        { name: "comuneDecesso", name: "Comune", value: datiDecesso.comune },
        { name: "dataDecesso", name: "Data", value: dateFormatter(datiDecesso.data) },
        { name: "", value: "" },
        { name: "", value: "" },
      ]);
    }
    
    result.dati.matrimonio = [];
    if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.matrimonio) {
      var datiMatrimonio = datiAnagrafica.datiStatoCivile.matrimonio;
      result.dati.matrimonio.push([
        { name: "coniugeMatrimonio", name: "Coniuge", value: (datiMatrimonio.coniuge.cognome?datiMatrimonio.coniuge.cognome:"")+" "+(datiMatrimonio.coniuge.nome?datiMatrimonio.coniuge.nome:"") },
        { name: "comuneMatrimonio", name: "Comune", value: datiMatrimonio.comune },
        { name: "dataMatrimonio", name: "Data", value: dateFormatter(datiMatrimonio.data) },
      ]);
    }

    result.dati.divorzio = [];
    if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.divorzio) {
      var datiDivorzio = datiAnagrafica.datiStatoCivile.divorzio;
      result.dati.divorzio.push([
        { name: "coniugeDivorzio", name: "Coniuge", value: (datiDivorzio.coniuge.cognome?datiDivorzio.coniuge.cognome:"")+" "+(datiDivorzio.coniuge.nome?datiDivorzio.coniuge.nome:"") },
        { name: "tribunale", value: datiDivorzio.tribunale },
        { name: "dataDivorzio", name: "Data", value: dateFormatter(datiDivorzio.data) },
      ]);
    }

    result.dati.vedovanza = [];
    if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.vedovanza) {
      var datiVedovanza = datiAnagrafica.datiStatoCivile.vedovanza;
      result.dati.vedovanza.push([
        { name: "coniugeVedovanza", name: "Coniuge", value: (datiVedovanza.coniuge.cognome?datiVedovanza.coniuge.cognome:"")+" "+(datiVedovanza.coniuge.nome?datiVedovanza.coniuge.nome:"") },
        { name: "comuneVedovanza", name: "Comune", value: datiVedovanza.comune },
        { name: "dataVedovanza", name: "Data", value: dateFormatter(datiVedovanza.data) },
      ]);
    }

    result.dati.unione_civile = [];
    if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.unioneCivile) {
      var datiUnioneCivile = datiAnagrafica.datiStatoCivile.unioneCivile;
      result.dati.unione_civile.push([
        { name: "coniugeUnioneCivile", name: "Unito civilmente", value: (datiUnioneCivile.unitoCivilmente.cognome?datiUnioneCivile.unitoCivilmente.cognome:"")+" "+(datiUnioneCivile.unitoCivilmente.nome?datiUnioneCivile.unitoCivilmente.nome:"") },
        { name: "comuneUnioneCivile", name: "Comune", value: datiUnioneCivile.comune },
        { name: "dataUnioneCivile", name: "Data", value: dateFormatter(datiUnioneCivile.data) },
      ]);
    }

    result.dati.scioglimento_unione_civile = [];
    if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.scioglimentoUnione) {
      var datiScioglimento = datiAnagrafica.datiStatoCivile.scioglimentoUnione;
      result.dati.scioglimento_unione_civile.push([
        { name: "coniugeScioglimentoUnione", name: "Unito civilmente", value: (datiUniondatiScioglimentoeCivile.unitoCivilmente.cognome?datiScioglimento.unitoCivilmente.cognome:"")+" "+(datiScioglimento.unitoCivilmente.nome?datiScioglimento.unitoCivilmente.nome:"") },
        { name: "comuneScioglimentoUnione", name: "Comune", value: datiScioglimento.comune },
        { name: "dataScioglimentoUnione", name: "Data", value: dateFormatter(datiScioglimento.data) },
      ]);
    }

    result.dati.autocertificazioni = [];
    if(demograficiData.test) {
      var testList = [{
        preText: "Nome documento ",
        text: <span>scarica documento <i className='fa fa-download'></i></span>,
        postText: todo("da dove si prende?","danger"),
        url: demograficiData.dominio+"/autocertificazione?codice_fiscale="+datiAnagrafica.codiceFiscale+"&nome=Nome documento"
      }]
      result.dati.autocertificazioni = [[
        { name:"listaAutocertificazioni", value: <DemograficiList list={testList}/>, html: true }
      ]]
    }

    result.dati.elettorale = [];
    if(demograficiData.test) {
      result.dati.elettorale = [[
          { name: "statusElettore", label: "Stato elettore", value: todo("da dove si prende?","danger") },
          { name: "iscrizione", value: todo("da dove si prende?","danger") },
          { name: "fascicolo", value: todo("da dove si prende?","danger") }
        ],[
          { name: "numeroDiGenerale", label: "Numero di generale", value: todo("da dove si prende?","danger") },
          { name: "sezioneDiAppartenenza", label: "Sezione di appartenenza", value: todo("da dove si prende?","danger") },
          { name: "sezionale", value: todo("da dove si prende?","danger") }
        ]
      ];
    }

    result.dati.certificati = []

    var selectTipiCertificato = []
    selectTipiCertificato.push(<option value="" disabled hidden>scegli il tipo di certificato da richiedere</option>)
    for(var t in demograficiData.tipiCertificato) {
      selectTipiCertificato.push(<option value={demograficiData.tipiCertificato[t].id}>{demograficiData.tipiCertificato[t].descrizione}</option>)
    }
    selectTipiCertificato = <select className="form-control" defaultValue="" name="tipoCertificato">{selectTipiCertificato}</select>

    var selectEsenzioni = []
    selectEsenzioni.push(<option value="">nessuna esenzione</option>)
    for(var e in demograficiData.esenzioniBollo) {
      selectEsenzioni.push(<option value={demograficiData.esenzioniBollo[e].id}>{demograficiData.esenzioniBollo[e].descrizione}</option>)
    }
    selectEsenzioni = <select className="form-control" defaultValue="" name="esenzioneBollo" id="esenzioneBollo">{selectEsenzioni}</select>

    var urlModifica = $("#dominio_portale").text()+"/dettagli_utente?modifica";
    var urlCarrello = $("#dominio_portale").text()+"/servizi/pagamenti/";
    var selectTipiDoc = []
    selectTipiDoc.push(<option value=""></option>)
    selectTipiDoc.push(<option value={demograficiData.esenzioniBollo[e].id}>{demograficiData.esenzioniBollo[e].descrizione}</option>);
    selectTipiDoc = <select className="form-control" defaultValue="" name="esenzioneBollo" id="esenzioneBollo">{selectEsenzioni}</select>

    // TODO aggiungere in base ai permessi
    // TODO alert dati documento mancanti
    var stringaRichiedente = datiAnagrafica.datiRichiedente.cognome.toUpperCase()+
    " "+datiAnagrafica.datiRichiedente.nome.toUpperCase()+
    " - "+(datiAnagrafica.datiRichiedente.tipo_documento=="CI"?"Carta d'Identità":datiAnagrafica.datiRichiedente.tipo_documento)+
    " n."+datiAnagrafica.datiRichiedente.numero_documento+
    " del "+dateFormatter(datiAnagrafica.datiRichiedente.data_documento)
    result.dati.certificati.push([
      { name:null, value: <p className="alert alert-info">Per i certificati diretti alla Pubblica Amministrazione ed Enti Erogatori di Pubblici Servizi (ASL, ENEL, POSTE, PREFETTURA, INPS, SUCCESSIONE ...) dev'essere compilata l'Autocertificazione.</p>, html: true }
    ],[
      { name:"nomeCognomeRichiesta", label: "Si richiede il certificato per", labelCols:4, valueSize:5, value: <span>{nominativo}</span> }
    ],[
      { name:"nomeCognomeRichiedente", label: "Il certificato viene richiesto da", labelCols:4, valueSize:5, value: <span>{stringaRichiedente} <a className="btn btn-default ml10" href={urlModifica}>Modifica</a></span> }
    ],[
      { name:"certificatoTipo", label: "Tipo certificato", labelCols:4, valueSize:5, value: selectTipiCertificato, html: true }
    ],[
      { name:"cartaLiberaBollo", label: "Il certificato dovrà essere rilasciato in Carta Libera o in Bollo?", labelCols:4, valueSize:5, value: <div>
        <label className="radio-inline">
              <input type="radio" name="certificatoBollo" id="carta_libera" defaultValue="false"/>Carta Libera
            </label>
            <label className="radio-inline">
              <input type="radio" name="certificatoBollo" id="bollo" defaultValue="true" defaultChecked="checked"/>
              Bollo
            </label>
      </div>, html: true }
    ],[
      { name:"certificatoEsenzione", label: "Esenzione", labelCols:4, valueSize:5, value: selectEsenzioni, html: true }
    ]);

    /*[
      { name:null, value: <p className="alert alert-info">In caso di certificato in Bollo, è necessario acquistare la marca da bollo preventivamente presso un punto vendita autorizzato; il numero identificativo, composto da 14 cifre, andrà poi riportato nel campo sottostante.</p>, html: true }
    ],*//*[
      { name:"identificativoBollo", label: "Inserire l'identificativo del bollo", value: <input className="form-control" type="text" name="certificatoBolloNum" defaultValue="" placeholder="01234567891234"/>, html: true },
      { name: "", value: "" }
    ],[
      { name: "nomeRichiedente", label: "Nome", labelCols:1, valueSize:2, value: datiAnagrafica.datiRichiedente.nome.toUpperCase() },
      { name: "cognomeRichiedente", label: "Cognome", labelCols:1, valueSize:2, value: datiAnagrafica.datiRichiedente.cognome.toUpperCase() },
      { name: "documentoRichiedente", label: "Documento", labelCols:1, valueSize:2, value: datiAnagrafica.datiRichiedente.tipo_documento+" "+datiAnagrafica.datiRichiedente.numero_documento },
      { name: "dataDocRichiedente", label: "Data", labelCols:1, valueSize:2, value: dateFormatter(datiAnagrafica.datiRichiedente.data_documento) },
    ],*/

    if(!datiAnagrafica.datiRichiedente.tipo_documento || !datiAnagrafica.datiRichiedente.data_documento || !datiAnagrafica.datiRichiedente.numero_documento ) {
      result.dati.certificati.push([
        { name:null, value: <p className="alert alert-danger">Attenzione: dati documento mancanti o incompleti. Completa i dati per abilitare l'invio della richiesta:</p>, html: true }
      ]);
      result.dati.certificati.push([
        { name:"", labelCols:2, valueSize:8, value: <div className="text-center"><a className="btn btn-default ml10" href={urlModifica}>Completa i dati documento</a></div>, html: true }
      ]);
    } else {
      result.dati.certificati.push([
        { name:"", labelCols:2, valueSize:8, value: <div className="text-center"><input type="submit" name="invia" className="btn btn-primary" value="Invia richiesta"/></div>, html: true },
        { name: "", labelCols:1, valueSize:1, value: <input type="hidden" name="authenticity_token" value={datiAnagrafica.csrf}/> },
      ]);
    }
  
    if(datiAnagrafica.certificati && datiAnagrafica.certificati.length) {
      result.dati.certificati.push([
        { name:null, value: <p className="alert alert-warning">Attenzione: si informa che i certificati sono scaricabili una volta sola.</p>, html: true }
      ]);
      result.dati.certificati.push([
          { name: "ricevuti", labelCols:1, value: <BootstrapTable
          id="tableCertificati"
          keyField={"data_inserimento"}
          data={datiAnagrafica.certificati}
          columns={[
            // { dataField: "id", text: "id" }, 
            { dataField: "nome_certificato", text: "Tipo certificato", formatter: tipoCertFormatter }, 
            { dataField: "codice_fiscale", text: "CF Intestatario" }, // non serve più? li mostro sulla scheda dell'intestatario
            { dataField: "stato", text: "Stato richiesta", formatter: statiFormatter }, 
            { dataField: "data_prenotazione", text: "Data richiesta", formatter: dateFormatter }, 
            // { dataField: "data_inserimento", text: "Emesso il", formatter: dateFormatter },
            // { dataField: "esenzione", text: "Esenzione", formatter: esenzioneFormatter },
            { dataField: "importo", text: "Importo", formatter: moneyFormatter },  
            { dataField: "documento", text: "Azioni", formatter: buttonFormatter },           
          ]}
          classes="table-responsive"
          striped
          hover
        />, html: true }
        ]
      );
      result.dati.certificati.push([
        { name:"", labelCols:1, valueSize:10, value: <div className="text-center"><a className="btn btn-primary ml10" id="btnCarrello" href={urlCarrello}>Vai al carrello</a></div>, html: true }
      ]);
    }

    if(datiAnagrafica.richiesteCertificati && datiAnagrafica.richiesteCertificati.length) {
      if(datiAnagrafica.certificati && !datiAnagrafica.certificati.length) {
        result.dati.certificati.push([
          { name:null, value: <p className="alert alert-warning">Attenzione: si informa che i certificati sono scaricabili una volta sola.</p>, html: true }
        ]);
      }
      result.dati.certificati.push([
          { name: "richiesti", labelCols:1, value: <BootstrapTable
          id="tableRichieste"
          keyField={"data_prenotazione"}
          data={datiAnagrafica.richiesteCertificati}
          columns={[
            // { dataField: "id", text: "id" }, 
            { dataField: "nome_certificato", text: "Tipo certificato", formatter: tipoCertFormatter }, 
            { dataField: "codice_fiscale", text: "CF Intestatario" }, // non serve più? li mostro sulla scheda dell'intestatario
            { dataField: "stato", text: "Stato richiesta", formatter: statiFormatter }, 
            { dataField: "data_prenotazione", text: "Data richiesta", formatter: dateFormatter },
            // { dataField: "esenzione", text: "Esenzione", formatter: esenzioneFormatter },
            { dataField: "importo", text: "Importo", formatter: moneyFormatter }            
          ]}
          classes="table-responsive"
          striped
          hover
        />, html: true }
        ]
      );
    }

    return result;
  }
  
  displayTabs() {
    var tabsHtml = [];
    var className = "active";
    for(var tabName in this.tabs) {
      if(this.state.dati[tabName].length) {
        var label = ucfirst(tabName.replace(/_/g," "));
        tabsHtml.push(<li key={tabName} role="presentation" className={className}><a href={"#"+tabName} aria-controls={tabName} role="tab" data-toggle={tabName}>{label}</a></li>);
        className = "";
      } else {
        console.log("dati for "+tabName+" not present");
      }
    }
    return <ul className="nav nav-tabs">{tabsHtml}</ul>
  }

  displayPanels() {
    var panelsHtml = [];
    var className = "";
    for(var tabName in this.tabs) {
      if(this.state.dati[tabName].length) {
        var form = "";
        if(tabName=="certificati") {
          form = <form className="panel-body form-horizontal" method="POST" action={demograficiData.dominio+"/richiedi_certificato"}>            
            <DemograficiForm rows={this.state.dati[tabName]} maxLabelCols="1"/>
          </form>
        } else {
          // readonly
          form = <div className="panel-body form-horizontal">
          <DemograficiForm rows={this.state.dati[tabName]}/>
        </div>
        }
        panelsHtml.push(<div role="tabpanel" key={"panel_"+tabName} className={"tab-pane"+className} id={tabName}>
          <div className="panel panel-default panel-tabbed">
            {form}
          </div>
        </div>);
        className = " hidden";
      }
    }
    
    return <div className="tab-content">{panelsHtml}</div>
  }

  render() {
    // console.log(datiAnagrafica);
    var found = this.state.datiCittadino && this.state.datiCittadino!=null && this.state.datiCittadino.length;
    var returnVal = <div className="alert alert-warning">Dati contribuente non presenti nel sistema</div>
    if(this.state.loading) {
      returnVal = <div className="alert alert-info">Caricamento...</div>
    }
    else if(this.state.error) {
      returnVal = <div className="alert alert-danger">{this.state.error_message}</div>
    } else if(found) {
      
      returnVal =       <div itemID="app_tributi">
        <h4>Dettagli persona</h4>
        <div className="form-horizontal"><DemograficiForm rows={this.state.datiCittadino}/></div>
        
        <p></p>

        <div>
      
          {this.displayTabs()}

          {this.displayPanels()}

        </div>
        {demograficiData.test?<pre style={{"whiteSpace": "break-spaces"}}><code>{this.state.debug?JSON.stringify(this.state.debug, null, 2):""}</code></pre>:""}

      </div>  
    } else {
      returnVal = <div className="alert alert-danger">Si è verificato un errore generico</div>
    }
    return(returnVal);
  }
}

if(document.getElementById('app_demografici_container') !== null){
  ReactDOM.render(<DettagliPersona />, document.getElementById('app_demografici_container') );
  var $links = $("#topbar").find(".row");
  $links.find("div").last().remove();
  $links.find("div").first().removeClass("col-lg-offset-3").removeClass("col-md-offset-3");
  $links.append('<div class="col-lg-2 col-md-2 text-center"><a href="'+$("dominio_portale").text()+'/" title="Sezione Privata">CIAO<br>'+$("#nome_utente").text()+'</a></div>');
  $links.append('<div class="col-lg-1 col-md-1 logout_link"><a href="logout" title="Logout"><span class="glyphicon glyphicon-log-out" aria-hidden="true"></span></a></div>');

  $('#portal_container').on('click', '.nav-tabs a', function(e){
    e.preventDefault();
    $(".tab-pane").addClass("hidden");
    $(".nav-tabs li").removeClass("active");
    $("#"+$(this).data("toggle")+".tab-pane").removeClass("hidden");
    $(this).parent().addClass("active");
  });

  $('#portal_container').on('click', 'a.btn-async', function(e){
    e.preventDefault();
    console.log("clicked async link");
    var url = $(this).attr("href");
    var $wait = $(this).parent().find(".wait-icon");
    var $done = $(this).parent().find(".done-icon");
    var $error = $(this).parent().find(".error-icon");
    console.log("got url "+url);
    console.log("displaying icons");
    $(this).hide();
    $wait.show().removeClass("hidden");
    $done.hide().removeClass("hidden");
    $error.hide().removeClass("hidden");
    

    // url = url.replace(".json","");
    console.log("doing request on "+url);
    $.ajax({   
      type: "POST",
      url: url,
      dataType: 'json',
      crossDomain: true,
      xhrFields: {
        withCredentials: true
      },
      // contentType: "application/json" ,
      contentType: "text/plain" ,
    }).done(function( response ) {
      console.log("request done");
      console.log(response);      
      $wait.hide();
      // TODO trovare un modo di recepire la risposta
      $done.show();
      // if(response.ok=="true") {
      //   $done.show();
      // } else {
      //   $error.show();
      // }
    }).fail(function(response) {
      console.log("request error");
      console.log(response);
      $wait.hide();
      // $error.show();
      // TODO trovare un modo di recepire la risposta
      $done.show();
    });
  });

  $('#portal_container').on('click', '.error-icon', function(e){
    e.preventDefault();
    $(this).parent().find("a.btn-async").show();
    $(this).hide();
  });
}