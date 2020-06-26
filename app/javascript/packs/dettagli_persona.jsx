window.appType = "external";

import React, { useState } from 'react';
import ReactDOM from 'react-dom';
// import $ from 'jquery';
// window.jQuery = $;
// window.$ = $;

import Select from 'react-select';
import BootstrapTable from 'react-bootstrap-table-next';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faCircleNotch, faShoppingCart, faPrint, faCheck, faExclamation, faDownload } from '@fortawesome/free-solid-svg-icons'

demograficiData.descrizioniStatus = {"D":"DECEDUTO", "R":"RESIDENTE", "A":"RESIDENTE AIRE", "I":"IRREPERIBILE", "E":"EMIGRATO"}

function buttonFormatter(cell,row) {
  var button = ""

  if (cell.indexOf("aggiungi_pagamento_pagopa")>-1 || cell.indexOf("inserisci_pagamento")>-1) { button = <span>
    <a className="btn btn-async" href={cell} title="Aggiungi al carrello"><FontAwesomeIcon icon={faShoppingCart} /></a>
    <a className="btn hidden wait-icon" title="Attendi..."><FontAwesomeIcon icon={faCircleNotch} spin /></a>
    <a className="btn hidden done-icon text-success" title="Pagamento aggiunto al carrello"><FontAwesomeIcon icon={faCheck} /></a>
    <a className="btn hidden error-icon text-danger" href="#" title="Errore durante l'aggiunta del pagamento"><FontAwesomeIcon icon={faExclamation} /></a>
  </span> }
  else if(cell.indexOf("servizi/pagamenti")>-1) { button = <span><a className="btn done-icon text-success" title="Pagamento aggiunto al carrello"><FontAwesomeIcon icon={faCheck} /></a></span> }
  else if(cell.indexOf("scarica_certificato")>-1) { button = <span><a className="btn" href={cell} title="Stampa"><FontAwesomeIcon icon={faPrint} /></a></span> }
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
    this.nostyle = props.nostyle;
    if(!this.nostyle){this.nostyle=false;}
    console.log("constructor end");
  }

  render() {
    console.log("rendering DemograficiList");
    console.log("list");
    console.log(this.list);
    console.log("linked");
    console.log(this.linked);
    console.log("nostyle");
    console.log(this.nostyle);
    var listItems = [];
    var html;
    var classNameLi = 'list-group-item';
    var classNameUl = 'list-group';
    var separator = <></>;
    if(this.nostyle) {
      classNameLi = 'btn';
      classNameUl = '';
      separator = <br/>;
    }
    if(this.list && this.list[0]) {
      if(this.linked) {
        listItems.push(this.list.map((item, index) => <><a className={classNameLi} key={item.text+index.toString()} href={item.url}>{item.preText?<span>{item.preText}</span> :""}{typeof(item.text.toLowerCase)=="function"&&item.text.toLowerCase().indexOf("scarica")>-1?<span><FontAwesomeIcon icon={faDownload}/></span>:item.text}{item.postText? <span className="badge">{item.postText}</span>:""}</a>{separator}</> ));
      } else {
        listItems.push(this.list.map((item, index) => <li className={classNameLi} key={index.toString()}>{item.preText?<span>{item.preText}</span> :""}<a href={item.url}>{typeof(item.text.toLowerCase)=="function"&&item.text.toLowerCase().indexOf("scarica")>-1?<span><FontAwesomeIcon icon={faDownload}/></span>:item.text}{item.postText? <span className="badge">{item.postText}</span>:""}</a></li>  ));
      }
    }
    if(this.linked) {
      html = <div className={classNameUl}>{listItems}</div>
    } else {
      html = <ul className={classNameUl}>{listItems}</ul>
    }
    console.log(html);
    return(html);
  }
}

class DettagliPersona extends React.Component{
  tabs= {
    "scheda_anagrafica":[],
    "nascita":[],
    "decesso":[],
    "matrimonio":[],
    "divorzio":[],
    "vedovanza":[],
    "unione_civile":[],
    "scioglimento_unione_civile":[], // TODO aggiungere dentro divorzio?
    // "elettorale":[],
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
    isSelf:false, 
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
    console.log($("#btnCarrello"));
    console.log($(".done-icon").not(".hidden"));
    $("#btnCarrello").removeClass("hidden").toggle($(".done-icon").not(".hidden").length>0);
    this.motivoEsenzione();
  }

  authenticate() {
    console.log("demograficiData.dominio: "+demograficiData.dominio);
    var self = this;
    console.log("Dettagli persona - Authenticating on "+demograficiData.dominio+"/authenticate...");
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
          state.isSelf = response.isSelf;
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

  motivoEsenzione() {
    $("#motivo_esenzione").parent().parent().toggle($("#esenzioneBollo").val()=="99");
  }

  formatData(datiAnagrafica) {
    var nominativo = datiAnagrafica.cognome+" "+datiAnagrafica.nome;
    var result = {"dati":{}, "isSelf": datiAnagrafica.isSelf };   
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
      ], 
    ];

    // così aggiungo una riga
    var genitori = [];
    if(datiAnagrafica.datiMaternita != null) {
      genitori.push(
        { name: "madre", value: datiAnagrafica.datiMaternita.cognome+" "+datiAnagrafica.datiMaternita.nome },
      );
    }
    if(datiAnagrafica.datiPaternita != null) {
      genitori.push(
        { name: "padre", value: datiAnagrafica.datiPaternita.cognome+" "+datiAnagrafica.datiPaternita.nome },
      );
    }
    if(genitori.length) {
      genitori.push({ name: "", value: "" }); 
      if(genitori.length==2){genitori.push({ name: "", value: "" });}
      result.dati.scheda_anagrafica.push(genitori);
    }

    result.dati.scheda_anagrafica.push([
      { name: "titoloStudio", label: "Titolo studio", value: datiAnagrafica.datiTitoloStudio!=null?datiAnagrafica.datiTitoloStudio.descrizione:"" },
      { name: "professione", label: "Professione", value: datiAnagrafica.datiProfessione!=null?datiAnagrafica.datiProfessione.descrizione:"" },
      { name: "", value: "" },
    ]);

    if(datiAnagrafica.datiIscrizione!=null) {
      var iscrizione = datiAnagrafica.datiIscrizione;
      var rilascio = []
      result.dati.scheda_anagrafica.push([
        { name:null, value: <h4>Dati iscrizione</h4>, html: true }
      ],[
        { name: "motivoIscrizione", label: "Motivo", value: iscrizione.motivo },
        { name: "dataDecorrenzaIscrizione", label: "Data decorrenza", value: dateFormatter(iscrizione.dataDecorrenza) },
        { name: "praticaIscrizione", label: "Pratica", value: "n."+iscrizione.numeroPratica+" proveniente da "+iscrizione.comuneProvenienza }
      ]);
    }

    if(datiAnagrafica.datiCancellazione!=null) {
      var cancellazione = datiAnagrafica.datiCancellazione;
      var rilascio = []
      result.dati.scheda_anagrafica.push([
        { name:null, value: <h4>Dati iscrizione</h4>, html: true }
      ],[
        { name: "motivoCancellazione", label: "Motivo", value: cancellazione.motivo },
        { name: "dataDecorrenzaCancellazione", label: "Data decorrenza", value: dateFormatter(cancellazione.dataDecorrenza) },
        { name: "praticaCancellazione", label: "Pratica", value: "n."+cancellazione.numeroPratica+" proveniente da "+cancellazione.comuneProvenienza }
      ]);
    }

    if(datiAnagrafica.datiTitoloSoggiorno!=null) {
      var documento = datiAnagrafica.datiTitoloSoggiorno;
      var rilascio = []
      if(documento.comuneRilascio) { rilascio.push("Comune di "+documento.comuneRilascio); }
      if(documento.consolatoRilascio) { rilascio.push("Consolato di "+documento.consolatoRilascio); }
      if(documento.questuraRilascio) { rilascio.push("Questura di "+documento.questuraRilascio); }
      result.dati.scheda_anagrafica.push([
        { name:null, value: <h4>Permesso di soggiorno</h4>, html: true }
      ],[
        { name: "titoloSoggiorno", label: "Permesso di soggiorno", value: documento.tipo+" n."+documento.numero+" del "+dateFormatter(documento.dataRilascio) },
        { name: "scadenza", value: dateFormatter(documento.dataScadenza) },
        { name: "comuneRilascio", label: "Rilasciato da", value: rilascio.join(", ") }
      ]);
    }

    result.dati.nascita = []
    if(datiAnagrafica.dataNascita) {
      result.dati.nascita = [[
          { name: "cognome", value: datiAnagrafica.cognome },
          { name: "nome", value: datiAnagrafica.nome },
          { name: "sesso", value: datiAnagrafica.sesso },
        ], [
          { name: "dataNascita", label: "Data nascita", value: datiAnagrafica.dataNascita },
          { name: "oraNascita", label: "Ora nascita", value: "" }, // non c'è
          { name: "comuneNascitaDescrizione", label: "Comune di nascita", value: datiAnagrafica.comuneNascitaDescrizione }, 
        ], [
          { name: "statoCivile", label: "Stato civile", value: datiAnagrafica.datiStatoCivile?datiAnagrafica.datiStatoCivile.statoCivile:"" },
          genitori.length?genitori[0]:{ name: "", value: "" },
          genitori.length?genitori[1]:{ name: "", value: "" },
        ], 
      ];
    }

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
      else if(documento.consolatoRilascio) { rilasciataDa = "Consolato di "+documento.consolatoRilascio; }
      result.dati.documenti.push([
        { name: "tipoDocumento", label: "Tipo", value: "Carta d'identità" },
        { name: "numero", value: documento.numero },
        { name: "stato", value: documento.validaEspatrio?"valida per espatrio":"non valida per espatrio" },
      ],[
        { name: "comuneRilascio", label: "Rilasciata da", value: rilasciataDa },
        { name: "dataRilascio", label: "In data", value: dateFormatter(documento.dataRilascio) },
        { name: "dataScadenza", label: "Scadenza", value: dateFormatter(documento.dataScadenza) },
      ]);
    }

    var altriDoc = []
    if(datiAnagrafica.datiVeicoli!=null) {
      var documento = datiAnagrafica.datiVeicoli;
      altriDoc.push(
        { name: "possessoVeicoli", label: "Possiede veicoli", value: documento.possesso=="S"?"sì":"no" }
      );
    }
    if(datiAnagrafica.datiPatente!=null) {
      var documento = datiAnagrafica.datiPatente;
      altriDoc.push(
        { name: "possessoPatente", label: "Possiede patente", value: documento.possesso=="S"?"sì":"no" }
      );
    }
    if(altriDoc.length) {
      altriDoc.push({ name: "", value: "" }); 
      if(altriDoc.length==2){altriDoc.push({ name: "", value: "" });}
      result.dati.documenti.push([{ name:null, value: <h4>Altre informazioni</h4>, html: true }]);
      result.dati.documenti.push(altriDoc);
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
          { name: "componenti", value: <DemograficiList list={famigliaFormatted} linked="true"/>, valueSize:5, html: true },
          { name: "", value: "" },
        ]
      ];
    }
    
    result.dati.decesso = [];
    if(datiAnagrafica.datiDecesso) {
      var datiDecesso = datiAnagrafica.datiDecesso;
      result.dati.decesso.push([
        { name: "nominativoDecesso", label: "Nominativo", value: nominativo },
        { name: "comuneDecesso", label: "Luogo del decesso", value: datiDecesso.comune },
        { name: "dataDecesso", label: "Data del decesso", value: dateFormatter(datiDecesso.data) },
        { name: "oraDecesso", label: "Ora del decesso", value: datiDecesso.data.replace(/[^T]*T*(.*)/g,'$1') },
      ]);
    }
    
    result.dati.matrimonio = [];
    if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.matrimonio) {
      var datiMatrimonio = datiAnagrafica.datiStatoCivile.matrimonio;
      result.dati.matrimonio.push([
        { name: "coniugeMatrimonio", label: "Coniuge", value: (datiMatrimonio.coniuge.cognome?datiMatrimonio.coniuge.cognome:"")+" "+(datiMatrimonio.coniuge.nome?datiMatrimonio.coniuge.nome:"") },
        { name: "comuneMatrimonio", label: "Comune celebrazione matrimonio", value: datiMatrimonio.comune },
        { name: "dataMatrimonio", label: "Data matrimonio", value: dateFormatter(datiMatrimonio.data) },
      ]);
    }

    result.dati.divorzio = [];
    if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.divorzio) {
      var datiDivorzio = datiAnagrafica.datiStatoCivile.divorzio;
      result.dati.divorzio.push([
        { name: "coniugeDivorzio", label: "Ex Coniuge", value: (datiDivorzio.coniuge.cognome?datiDivorzio.coniuge.cognome:"")+" "+(datiDivorzio.coniuge.nome?datiDivorzio.coniuge.nome:"") },
        { name: "sentenzaDivorzio", label: "Tipo sentenza", value: datiDivorzio.tipo },
        { name: "dataDivorzio", label: "Data sentenza", value: dateFormatter(datiDivorzio.dataSentenza) },
      ],[
        { name: "comuneDivorzio", label: "Comune divorzio", value: datiDivorzio.comune },
        { name: "tribunaleDivorzio", label: "Tribunale divorzio", value: datiDivorzio.tribunale },
        { name: "", value: "" },
      ]);
    }

    result.dati.vedovanza = [];
    if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.vedovanza) {
      var datiVedovanza = datiAnagrafica.datiStatoCivile.vedovanza;
      result.dati.vedovanza.push([
        { name: "coniugeVedovanza", label: "Coniuge", value: (datiVedovanza.coniuge.cognome?datiVedovanza.coniuge.cognome:"")+" "+(datiVedovanza.coniuge.nome?datiVedovanza.coniuge.nome:"") },
        { name: "dataVedovanza", label: "Data morte", value: dateFormatter(datiVedovanza.data) },
        { name: "comuneVedovanza", label: "Comune morte", value: datiVedovanza.comune },
      ]);
    }

    result.dati.unione_civile = [];
    if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.unioneCivile) {
      var datiUnioneCivile = datiAnagrafica.datiStatoCivile.unioneCivile;
      result.dati.unione_civile.push([
        { name: "coniugeUnioneCivile", label: "Unito civilmente", value: (datiUnioneCivile.unitoCivilmente.cognome?datiUnioneCivile.unitoCivilmente.cognome:"")+" "+(datiUnioneCivile.unitoCivilmente.nome?datiUnioneCivile.unitoCivilmente.nome:"") },
        { name: "comuneUnioneCivile", label: "Comune unione civile", value: datiUnioneCivile.comune },
        { name: "dataUnioneCivile", label: "Data unione civile", value: dateFormatter(datiUnioneCivile.data) },
      ]);
    }

    result.dati.scioglimento_unione_civile = [];
    if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.scioglimentoUnione) {
      var datiScioglimento = datiAnagrafica.datiStatoCivile.scioglimentoUnione;
      result.dati.scioglimento_unione_civile.push([
        { name: "coniugeScioglimentoUnione", label: "Unito civilmente", value: (datiUniondatiScioglimentoeCivile.unitoCivilmente.cognome?datiScioglimento.unitoCivilmente.cognome:"")+" "+(datiScioglimento.unitoCivilmente.nome?datiScioglimento.unitoCivilmente.nome:"") },
        { name: "comuneScioglimentoUnione", label: "Comune scioglimento", value: datiScioglimento.comune },
        { name: "dataScioglimentoUnione", label: "Data scioglimento", value: dateFormatter(datiScioglimento.data) },
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
        { name:"listaAutocertificazioni", label:"Autocertificazioni", value: <DemograficiList list={testList}/>, html: true }
      ]]
    }
    if(datiAnagrafica.autocertificazioni) {
      result.dati.autocertificazioni = [[
        { name:"", labelCols:0, valueSize:12, value: <DemograficiList list={datiAnagrafica.autocertificazioni} linked="true" nostyle="true"/>, html: true }
      ]]
    }

    // result.dati.elettorale = [];
    // if(demograficiData.test) {
    //   result.dati.elettorale = [[
    //       { name: "statusElettore", label: "Stato elettore", value: todo("da dove si prende?","danger") },
    //       { name: "iscrizione", value: todo("da dove si prende?","danger") },
    //       { name: "fascicolo", value: todo("da dove si prende?","danger") }
    //     ],[
    //       { name: "numeroDiGenerale", label: "Numero di generale", value: todo("da dove si prende?","danger") },
    //       { name: "sezioneDiAppartenenza", label: "Sezione di appartenenza", value: todo("da dove si prende?","danger") },
    //       { name: "sezionale", value: todo("da dove si prende?","danger") }
    //     ]
    //   ];
    // }

    if(datiAnagrafica.certificati) {
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
      selectEsenzioni = <select className="form-control" defaultValue="" name="esenzioneBollo" onChange={this.motivoEsenzione} id="esenzioneBollo">{selectEsenzioni}</select>

      var urlModifica = $("#dominio_portale").text()+"/dettagli_utente?modifica";
      var urlCarrello = $("#dominio_portale").text()+"/servizi/pagamenti/";
      var selectTipiDoc = []
      selectTipiDoc.push(<option value=""></option>)
      selectTipiDoc.push(<option value={demograficiData.esenzioniBollo[e].id}>{demograficiData.esenzioniBollo[e].descrizione}</option>);
      selectTipiDoc = <select className="form-control" defaultValue="" name="esenzioneBollo" id="esenzioneBollo">{selectEsenzioni}</select>

      // TODO **IMPORTANT** aggiungere controlli validità dati
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
        { name:null, value: <p className="alert alert-info">Per richiedere il certificato è necessario che le informazioni riguardanti il tuo documento di identificazione siano aggiornate ed il documento non sia scaduto. Verifica la correttezza dei tuoi dati prima di proseguire:</p>, html: true }
      ],[
        { name:"nomeCognomeRichiedente", label: "Il certificato viene richiesto da", labelCols:4, valueSize:5, value: <span>{stringaRichiedente} <a className="btn btn-default ml10" href={urlModifica}>Modifica</a></span> }
      ],[
        { name:"certificatoTipo", label: "Tipo certificato", labelCols:4, valueSize:5, value: selectTipiCertificato, html: true }
      ],[
        { name:"cartaLiberaBollo", label: "Il certificato dovrà essere rilasciato in Carta Libera o in Bollo?", labelCols:4, valueSize:5, value: <>
          <label className="radio-inline">
                <input type="radio" name="certificatoBollo" id="carta_libera" defaultValue="false"/>Carta Libera
              </label>
              <label className="radio-inline">
                <input type="radio" name="certificatoBollo" id="bollo" defaultValue="true" defaultChecked="checked"/>
                Bollo
              </label>
        </>, html: true }
      ],[
        { name:"certificatoEsenzione", label: "Esenzione", labelCols:4, valueSize:5, value: selectEsenzioni, html: true }
      ],[
        { name:"altroMotivoEsenzione", label: "Specificare il motivo dell'esenzione", labelCols:4, valueSize:5, value: <input className="form-control" type="text"  id="motivo_esenzione" name="motivoEsenzione" />, html: true }
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
          { name:"", labelCols:2, valueSize:8, value: <div className="text-center"><a className="btn btn-default" href={urlModifica}>Completa i dati documento</a></div>, html: true }
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
          { name:"", labelCols:1, valueSize:10, value: <div className="text-center"><a className="btn btn-primary hidden" id="btnCarrello" href={urlCarrello}>Vai al carrello</a></div>, html: true }
        ]);
        result.dati.certificati.push([
            { name: "Richiesti", labelCols:1, value: <BootstrapTable
            id="tableCertificati"
            keyField={"id"}
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
      }
    }

    return result;
  }
  
  displayTabs() {
    var tabsHtml = [];
    var className = "active";
    for(var tabName in this.tabs) {
      if(typeof(this.state.dati[tabName])!="undefined" && this.state.dati[tabName].length) {
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
      if(typeof(this.state.dati[tabName])!="undefined" && this.state.dati[tabName].length) {
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
    
    if(typeof(this.state) == "undefined") {
      returnVal = <div className="alert alert-danger">Si è verificato un errore, si prega di riprovare.</div>
    } else if(this.state.loading) {
      returnVal = <div className="alert alert-info">Caricamento...</div>
    }
    else if(this.state.error) {
      returnVal = <div className="alert alert-danger">{this.state.error_message}</div>
    } else if(found) {
      
      returnVal =       <div itemID="app_tributi">
        <h3>Dettagli persona</h3>
        <div className="form-horizontal"><DemograficiForm rows={this.state.datiCittadino}/></div>
        
        <p></p>

        <div>
      
          {this.displayTabs()}

          {this.displayPanels()}

        </div>

        <div className="bottoni_pagina mb20">
          <div className="row">
            <div className="col-lg-6 col-md-6 col-sm-12 col-xs-12">
              <div className="back">
                {this.state.backToSearch?<a className="btn" href="/ricerca_anagrafiche">Torna alla ricerca</a>:<a className="btn" href="/portale">Torna al portale</a>}
                
              </div>
              {this.state.isSelf?"":<a className="btn btn-default ml10" href="/self">Torna alla tua anagrafica</a>}
              <a className="btn btn-default ml10" href="/ricerca_anagrafiche">Ricerca anagrafiche</a>
            </div>
          </div>
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
  $links.append('<div class="col-lg-2 col-md-2 text-center"><a href="/portale" title="Sezione Privata">CIAO<br>'+$("#nome_utente").text()+'</a></div>');
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
    
    console.log("doing request on "+url);
    $.ajax({   
      type: "POST",
      url: url,
      dataType: 'json',
      crossDomain: true,
      contentType: "text/plain" ,
    }).done(function( response ) {
      console.log("request done");
      console.log(response);      
      $wait.hide();
      if(response.ok) {
        $done.show();
      } else {
        $error.show();
      }
      $("#btnCarrello").toggle($(".done-icon:visible").length>0);
    }).fail(function(response) {
      console.log("request error");
      console.log(response);
      $wait.hide();
      $error.show();
      $("#btnCarrello").toggle($(".done-icon:visible").length>0);
    });
  });

  $('#portal_container').on('click', 'a.error-icon', function(e){
    e.preventDefault();
    $(this).parent().find("a.btn-async").show();
    $(this).hide();
  });
}
