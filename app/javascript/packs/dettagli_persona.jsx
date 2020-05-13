window.appType = "external";

import React, { useState } from 'react';
import ReactDOM from 'react-dom';
// import $ from 'jquery';
// window.jQuery = $;
// window.$ = $;

import Select from 'react-select';
import BootstrapTable from 'react-bootstrap-table-next';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faCircleNotch } from '@fortawesome/free-solid-svg-icons'

var dominio = window.location.protocol+"//"+window.location.hostname+(window.location.port!=""?":"+window.location.port:"");
var test = false;
var descrizioniStatus = {"D":"deceduto", "R":"residente", "A":"residente AIRE"}

function dateToUser(dateTimeString) {
  var formatted = "";
  if(dateTimeString) {
    var date = new Date(dateTimeString.replace(/-/g,"/").replace(/T/g," "));
    formatted = date.toLocaleDateString("IT");
  }
  return formatted;
}

function todo(message, type) {
  if(typeof(type)=="undefined") { type="warning"; }
  if(test) {
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
          valueSize = fieldCols;
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
    "scioglimento_unione_civile":[],
    "elettorale":[],
    "documenti":[],
    "famiglia":[],
    "autocertificazioni":[],
    "richiedi_certificato":[],
  }

  state = {
    token:false, 
    dati:{},   
    datiCittadino: [],
    loading: true
  } 

  constructor(props){
    super(props);
    
    this.authenticate();
  }
  
  componentDidUpdate(prevProps, prevState, snapshot) {
    
    console.log("DettagliPersona did update");
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
        if($(this).attr("id")=="immobiliImu" || $(this).attr("id")=="immobiliTasi" || $(this).attr("id")=="immobiliTari") {
          $("#"+$(this).attr("id")+" li div:nth-of-type(1)").attr("class","cell-wide-4");
        }
      } else  { console.log("tableToUl is not a function ("+typeof(tableToUl)+") or no css available for responsive tables"); } 
    });
  }

  authenticate() {
    console.log("dominio: "+dominio);
    var self = this;
    console.log("Authenticating on "+dominio+"/authenticate...");
    $.get(dominio+"/authenticate").done(function( response ) {
      console.log("response is loaded");
      console.log(response);
      if(response.hasError) {
      } else {
        switch(response.permessi) {
          // TODO gestire permessi visualizzazione
          case "ricercare_anagrafiche":
            break;
          case "ricercare_anagrafiche_no_sensibili":
            break;
          case "elencare_anagrafiche":
            break;
          case "professionisti":
            break;
          case "vedere_solo_famiglia":
            break;
          default:
            self.ricercaIndividui();
            break;
        }
      }
    }).fail(function(response) {
      console.log("authentication fail!");
      console.log(response);
    });
  } 

  ricercaIndividui() {
    this.state.loading = true;
    for(var tabName in this.tabs) {
      this.state.dati[tabName] = [];
    }
    var self = this;
    console.log("ricercaIndividui...");
    $.get(dominio+"/ricerca_individui", {}).done(function( response ) {
      console.log("ricercaIndividui response is loaded");
      console.log(response);
      if(response.hasError) {
        console.log("response error");
      } else {
        var state = self.state;
        state.debug = response;
        response = self.formatData(response);
        state.loading = false;
        state.dati = response.dati;
        state.datiCittadino = response.datiCittadino;
        self.setState(state);
      }
    }).fail(function(response) {
      console.log("ricercaIndividui fail!");
      console.log(response);
    });
  }

  formatData(datiAnagrafica) {
    var result = {"dati":{}};
    result.datiCittadino = [[
        { name: "nominativo", value: datiAnagrafica.cognome+" "+datiAnagrafica.nome },
        { name: "indirizzo", value: datiAnagrafica.indirizzo },
      ], [
        // TODO chiedere elenco stati a giambanco
        { name: "status", value: descrizioniStatus[datiAnagrafica.posizioneAnagrafica] },
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
        { name: "codiceTitoloStudio", label: "Titolo studio", value: datiAnagrafica.datiTitoloStudio?datiAnagrafica.datiTitoloStudio.codiceTitoloStudio:"" },
        { name: "codiceProfessione", label: "Professione", value: datiAnagrafica.datiProfessione?datiAnagrafica.datiProfessione.codiceProfessione:"" },
        { name: "", value: "" },
      ]
    ];

    result.dati.documenti = [];

    // if(test) {
    //   result.dati.documenti.push([
    //     { name: "numero", value: documento.numero },
    //     { name: "stato", value: todo("manca l'informazione","danger") },
    //     { name: "dataRilascio", label: "In data", value: dateToUser(documento.dataRilascio) },
    //     { name: "scadenza", value: todo("manca l'informazione","danger") },
    //   ]);
    // }

    if(datiAnagrafica.datiCartaIdentita && datiAnagrafica.datiCartaIdentita.length) {
      var documento = datiAnagrafica.datiCartaIdentita;
      var rilasciataDa = "";
      if(documento.comuneRilascio) { rilasciataDa = "Comune di "+documento.comuneRilascio; }
      else if(documento.consolatoRilascio) { rilasciataDa = "Comune di "+documento.consolatoRilascio; }
      result.dati.documenti.push([
        { name: "tipoDocumento", label: "Tipo", value: "Carta d'identit&agrave;" },
        { name: "numero", value: documento.numero },
        { name: "comuneRilascio", label: "Rilasciata da", value: rilasciataDa },
        // { name: "stato", value: todo("manca l'informazione","danger") },
        { name: "dataRilascio", label: "In data", value: dateToUser(documento.dataRilascio) },
        // { name: "scadenza", value: todo("manca l'informazione","danger") },
      ]);
    }

    if(datiAnagrafica.datiTitoloSoggiorno && datiAnagrafica.datiTitoloSoggiorno.length) {
      var documento = datiAnagrafica.datiTitoloSoggiorno;
      var rilasciataDa = "";
      if(documento.comuneRilascio) { rilasciataDa = "Comune di "+documento.comuneRilascio; }
      else if(documento.consolatoRilascio) { rilasciataDa = "Comune di "+documento.consolatoRilascio; }
      result.dati.documenti.push([
        { name: "tipoDocumento", label: "Tipo", value: "Titolo di soggiorno" },
        { name: "numero", value: documento.numero },
        { name: "comuneRilascio", label: "Rilasciato da", value: rilasciataDa },
        { name: "dataRilascio", label: "In data", value: dateToUser(documento.dataRilascio) },
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

    var famigliaFormatted = false;
    if(datiAnagrafica.famiglia){
      famigliaFormatted = []
      for (var componente in datiAnagrafica.famiglia) {
        famigliaFormatted.push({
          preText: null,
          text: datiAnagrafica.famiglia[componente].cognome+" "+datiAnagrafica.famiglia[componente].nome,
          postText: datiAnagrafica.famiglia[componente].relazioneParentela,
          url: dominio+"/dettagli_persona?codice_fiscale="+datiAnagrafica.famiglia[componente].codiceFiscale
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
    
    result.dati.decesso = [];
    if(datiAnagrafica.datiDecesso) {
      var datiDecesso = datiAnagrafica.datiDecesso;
      result.dati.decesso.push([
        { name: "comuneDecesso", name: "Comune", value: datiDecesso.comune },
        { name: "dataDecesso", name: "Data", value: dateToUser(datiDecesso.data) },
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
        { name: "dataMatrimonio", name: "Data", value: dateToUser(datiMatrimonio.data) },
      ]);
    }

    result.dati.divorzio = [];
    if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.divorzio) {
      var datiDivorzio = datiAnagrafica.datiStatoCivile.divorzio;
      result.dati.divorzio.push([
        { name: "coniugeDivorzio", name: "Coniuge", value: (datiDivorzio.coniuge.cognome?datiDivorzio.coniuge.cognome:"")+" "+(datiDivorzio.coniuge.nome?datiDivorzio.coniuge.nome:"") },
        { name: "tribunale", value: datiDivorzio.tribunale },
        { name: "dataDivorzio", name: "Data", value: dateToUser(datiDivorzio.data) },
      ]);
    }

    result.dati.vedovanza = [];
    if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.vedovanza) {
      var datiVedovanza = datiAnagrafica.datiStatoCivile.vedovanza;
      result.dati.vedovanza.push([
        { name: "coniugeVedovanza", name: "Coniuge", value: (datiVedovanza.coniuge.cognome?datiVedovanza.coniuge.cognome:"")+" "+(datiVedovanza.coniuge.nome?datiVedovanza.coniuge.nome:"") },
        { name: "comuneVedovanza", name: "Comune", value: datiVedovanza.comune },
        { name: "dataVedovanza", name: "Data", value: dateToUser(datiVedovanza.data) },
      ]);
    }

    result.dati.unione_civile = [];
    if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.unioneCivile) {
      var datiUnioneCivile = datiAnagrafica.datiStatoCivile.unioneCivile;
      result.dati.unione_civile.push([
        { name: "coniugeUnioneCivile", name: "Unito civilmente", value: (datiUnioneCivile.unitoCivilmente.cognome?datiUnioneCivile.unitoCivilmente.cognome:"")+" "+(datiUnioneCivile.unitoCivilmente.nome?datiUnioneCivile.unitoCivilmente.nome:"") },
        { name: "comuneUnioneCivile", name: "Comune", value: datiUnioneCivile.comune },
        { name: "dataUnioneCivile", name: "Data", value: dateToUser(datiUnioneCivile.data) },
      ]);
    }

    result.dati.scioglimento_unione_civile = [];
    if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.scioglimentoUnione) {
      var datiScioglimento = datiAnagrafica.datiStatoCivile.scioglimentoUnione;
      result.dati.scioglimento_unione_civile.push([
        { name: "coniugeScioglimentoUnione", name: "Unito civilmente", value: (datiUniondatiScioglimentoeCivile.unitoCivilmente.cognome?datiScioglimento.unitoCivilmente.cognome:"")+" "+(datiScioglimento.unitoCivilmente.nome?datiScioglimento.unitoCivilmente.nome:"") },
        { name: "comuneScioglimentoUnione", name: "Comune", value: datiScioglimento.comune },
        { name: "dataScioglimentoUnione", name: "Data", value: dateToUser(datiScioglimento.data) },
      ]);
    }

    result.dati.autocertificazioni = [];
    if(test) {
      var testList = [{
        preText: "Nome documento ",
        text: <span>scarica documento <i className='fa fa-download'></i></span>,
        postText: todo("da dove si prende?","danger"),
        url: dominio+"/autocertificazionei?codice_fiscale="+datiAnagrafica.codiceFiscale+"&nome=Nome documento"
      }]
      result.dati.autocertificazioni = [[
        { name:"listaAutocertificazioni", value: <DemograficiList list={testList}/>, html: true }
      ]]
    }

    result.dati.elettorale = [];
    if(test) {
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

    var selectTipiCertificato = []
    selectTipiCertificato.push(<option value="" disabled hidden>scegli il tipo di certificato da richiedere</option>)
    for(var t in tipiCertificato) {
      selectTipiCertificato.push(<option value={tipiCertificato[t].id}>{tipiCertificato[t].descrizione}</option>)
    }
    selectTipiCertificato = <select className="form-control" defaultValue="" name="tipoCertificato">{selectTipiCertificato}</select>

    var selectEsenzioni = []
    selectEsenzioni.push(<option value="">nessuna esenzione</option>)
    for(var e in esenzioniBollo) {
      selectEsenzioni.push(<option value={esenzioniBollo[e].id}>{esenzioniBollo[e].descrizione}</option>)
    }
    selectEsenzioni = <select className="form-control" defaultValue="" name="esenzioneBollo">{selectEsenzioni}</select>

    result.dati.richiedi_certificato = [[
      { name:null, value: <p className="alert alert-info">Per i certificati diretti alla Pubblica Amministrazione ed Enti Erogatori di Pubblici Servizi (ASL, ENEL, POSTE, PREFETTURA, INPS, SUCCESSIONE ...) dev'essere compilata l'Autocertificazione.</p>, html: true }
    ],[
      { name:"nomeCognomeRichiesta", label: "Si richiede il certificato per", value: datiAnagrafica.cognome+" "+datiAnagrafica.nome },
      { name:"tipoCertificato", label: "Tipo certificato", value: selectTipiCertificato, html: true }
    ],[
      { name:"cartaLiberaBollo", label: "Il certificato dovrà essere rilasciato in Carta Libera o in Bollo?", value: <div>
        <label className="radio-inline">
              <input type="radio" name="dati[bollo]" id="carta_libera" defaultValue="false"/>Carta Libera
            </label>
            <label className="radio-inline">
              <input type="radio" name="dati[bollo]" id="bollo" defaultValue="true" defaultChecked="checked"/>
              Bollo
            </label>
      </div>, html: true },
     { name:"tipoEsenzione", label: "Esenzione", value: selectEsenzioni, html: true }
    ],[
      { name:null, value: <p className="alert alert-info">In caso di certificato in Bollo, è necessario acquistare la marca da bollo preventivamente presso un punto vendita autorizzato; il numero identificativo, composto da 14 cifre, andrà poi riportato nel campo sottostante.</p>, html: true }
    ],[
      { name:"identificativoBollo", label: "Inserire l'identificativo del bollo", value: <input className="form-control" type="text" name="dati[bollo_numero]" defaultValue="" placeholder="01234567891234"/>, html: true },
      { name: "", value: "" }
    ],[
      { name:"", value: <input type="submit" name="invia" className="btn btn-default" value="Invia richiesta"/>, html: true }
    ]]

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
      }
    }
    return <ul className="nav nav-tabs">{tabsHtml}</ul>
  }

  displayPanels() {
    var panelsHtml = [];
    var className = "";
    for(var tabName in this.tabs) {
      if(this.state.dati[tabName].length) {
        panelsHtml.push(<div role="tabpanel" key={"panel_"+tabName} className={"tab-pane"+className} id={tabName}>
          <div className="panel panel-default panel-tabbed">
            <div className="panel-body form-horizontal">
              <DemograficiForm rows={this.state.dati[tabName]} maxLabelCols={tabName=="certificazione"?4:2}/>
            </div>
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
    else if(found) {
      returnVal =       <div itemID="app_tributi">
        <h4>Dettagli persona</h4>
        <div className="form-horizontal"><DemograficiForm rows={this.state.datiCittadino}/></div>
        
        <p></p>

        <div>
      
          {this.displayTabs()}

          {this.displayPanels()}

        </div>  

        {test?<pre style={{"whiteSpace": "break-spaces"}}><code>{this.state.debug?JSON.stringify(this.state.debug, null, 2):""}</code></pre>:""}

      </div>  
    }
    return(returnVal);
  }
}

if(document.getElementById('app_demografici_container') !== null){
  ReactDOM.render(<DettagliPersona />, document.getElementById('app_demografici_container') );
  var $links = $("#topbar").find(".row");
  $links.find("div").last().remove();
  $links.find("div").first().removeClass("col-lg-offset-3").removeClass("col-md-offset-3");
  $links.append('<div class="col-lg-2 col-md-2 text-center"><a href="'+$("#dominio_portale").text()+'/" title="Sezione Privata">CIAO<br>'+$("#nome_utente").text()+'</a></div>');
  $links.append('<div class="col-lg-1 col-md-1 logout_link"><a href="'+$("#dominio_portale").text()+'/autenticazione/logout" title="Logout"><span class="glyphicon glyphicon-log-out" aria-hidden="true"></span></a></div>');

  console.log("hidden test is "+$(".hidden.test").length);
  test = $(".hidden.test").length;

  $('#portal_container').on('click', '.nav-tabs a', function(e){
    e.preventDefault();
    $(".tab-pane").addClass("hidden");
    $(".nav-tabs li").removeClass("active");
    $("#"+$(this).data("toggle")+".tab-pane").removeClass("hidden");
    $(this).parent().addClass("active");
  });
}