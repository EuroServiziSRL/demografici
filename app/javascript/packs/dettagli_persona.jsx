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

function displayForm(rows, width) {
  // console.log(cell);
  if( typeof(width) == "undefined" ) { width = 12; }
  var rowsHtml = []
  
  for(var r in rows) {
    var fieldsHtml = [];
    var fields = rows[r];
    var fieldSize = width/fields.length;
    var labelSize = Math.floor(fieldSize/3);
    if(labelSize>2) { labelSize = 2; } // senò è enorme dai
    var valueSize = fieldSize-labelSize;
    for(var f in fields) {
      if( typeof(fields[f].labelSize) == "undefined" ) { fields[f].labelSize = labelSize; }
      if( typeof(fields[f].valueSize) == "undefined" ) { fields[f].valueSize = valueSize; }
      if( typeof(fields[f].label) == "undefined" ) { fields[f].label = ucfirst(fields[f].name); }
      var labelClass = "col-lg-"+fields[f].labelSize+" control-label";
      var valueClass = "col-lg-"+fields[f].valueSize;
      fieldsHtml.push(<label key={"label"+f.toString()} htmlFor={fields[f].name} className={labelClass}>{fields[f].label}</label>)
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

function displayList(list) {
  var listItems = []
  if(list && list[0]) {
    if(list[0].linked) {
      listItems.push(list.map((item, index) => <a  className="list-group-item" key={index.toString()} href={item.url}>{item.preText?<span>{item.preText}</span> :""}{item.text}{item.postText? <span className="badge">{item.postText}</span>:""}</a>  ));
    } else {
      listItems.push(list.map((item, index) => <li className="list-group-item" key={index.toString()}>{item.preText?<span>{item.preText}</span> :""}<a href={item.url}>{item.text}{item.postText? <span className="badge">{item.postText}</span>:""}</a></li>  ));
    }
  }
  if(list && list[0] && list[0].linked) {
    return <div className="list-group">{listItems}</div>
  } else {
    return <ul className="list-group">{listItems}</ul>
  }
}

function todo(message, type) {
  if(typeof(type)=="undefined") { type="warning"; }
  if(test) {
    return <span className={"ml10 alert alert-"+type}>({message})</span>
  }
}

function ucfirst(str){
  return str.replace(/(\b)([a-zA-Z])/,
    function(firstLetter){
      return   firstLetter.toUpperCase();
    });
}

class DettagliPersona extends React.Component{

  state = {
    datiAnagrafica:false,
    token:false,
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
          case "ricercare_anagrafiche":
            // TODO
            break;
          case "ricercare_anagrafiche_no_sensibili":
            // TODO
            break;
          case "elencare_anagrafiche":
            // TODO
            break;
          case "professionisti":
            // TODO
            break;
          case "vedere_solo_famiglia":
            // TODO
            break;
          default:
            self.ricercaIndividuiSelf();
            break;
        }
      }
    }).fail(function(response) {
      console.log("authentication fail!");
      console.log(response);
    });
  } 

  ricercaIndividuiSelf() {
    var self = this;
    console.log("ricercaIndividuiSelf...");
    $.get(dominio+"/ricerca_individui", {}).done(function( response ) {
      console.log("ricercaIndividuiSelf response is loaded");
      console.log(response);
      if(response.hasError) {
        console.log("response error");
      } else {
        var state = self.state;
        state.datiAnagrafica = response;
        self.setState(state);
      }
    }).fail(function(response) {
      console.log("ricercaIndividuiSelf fail!");
      console.log(response);
    });
  }

  render(){
    var datiAnagrafica = this.state.datiAnagrafica;
    // console.log(datiAnagrafica);
    var returnVal = <div className="alert alert-warning">Dati contribuente non presenti nel sistema</div>
    if(datiAnagrafica!=null) {
      var datiCittadino = [[
          { name: "nominativo", value: datiAnagrafica.cognome+" "+datiAnagrafica.nome },
          { name: "indirizzo", value: <span>{datiAnagrafica.indirizzo}{todo("normale che sia vuoto?")}</span> },
        ], [
          { name: "status", value: datiAnagrafica.posizioneAnagrafica }, // verificare se tabella corrispondenza, fare anche a mano
          { name: "codiceCittadino", label: "Numero individuale", value: datiAnagrafica.codiceCittadino },
        ]
      ];
      var anagrafica = [[
          { name: "cognome", value: datiAnagrafica.cognome },
          { name: "nome", value: datiAnagrafica.nome },
          { name: "sesso", value: datiAnagrafica.sesso },
        ], [
          { name: "codiceFiscale", label: "Codice Fiscale", value: datiAnagrafica.codiceFiscale },
          { name: "dataNascita", label: "Data di nascita", value: datiAnagrafica.dataNascita },
          { name: "codiceIstatComuneNascitaItaliano", label: "Comune di nascita", value: datiAnagrafica.codiceIstatComuneNascitaItaliano }, // da tabella da aggiungere in db, usare codice istat
        ], [
          { name: "indirizzo", label: "Via di residenza", value: <span>{datiAnagrafica.indirizzo}{todo("uguale a indirizzo?", "warning")}</span> },
          { name: "descrizioneCittadinanza", label: "Cittadinanza", value: datiAnagrafica.descrizioneCittadinanza },
          { name: "statoCivile", label: "Stato civile", value: datiAnagrafica.datiStatoCivile?datiAnagrafica.datiStatoCivile.statoCivile:"" },
        ], [
          { name: "codiceTitoloStudio", label: "Titolo studio", value: datiAnagrafica.datiTitoloStudio?datiAnagrafica.datiTitoloStudio.codiceTitoloStudio:"" },
          { name: "codiceProfessione", label: "Professione", value: datiAnagrafica.datiProfessione?datiAnagrafica.datiProfessione.codiceProfessione:"" },
          { name: "", value: "" },
        ]
      ];
      // da mostrare se almeno uno datiCartaIdentita, datiVeicoli, datiPatente
      var documenti = [[
          { name: "numero", value: datiAnagrafica.numero },
          { name: "stato", value: todo("manca l'informazione","danger") },
          { name: "dataRilascio", label: "In data", value: datiAnagrafica.dataRilascio },
          { name: "scadenza", value: todo("manca l'informazione","danger") },
        ]
      ];
      var famigliaFormatted = false;
      if(datiAnagrafica.famiglia){
        famigliaFormatted = []
        for (var componente in datiAnagrafica.famiglia) {
          famigliaFormatted.push({
            preText: null,
            text: datiAnagrafica.famiglia[componente].cognome+" "+datiAnagrafica.famiglia[componente].nome,
            postText: datiAnagrafica.famiglia[componente].codiceRelazioneParentelaANPR,
            url: dominio+"/dettagli_persona?codice_fiscale="+datiAnagrafica.famiglia[componente].codiceFiscale,
            linked: true
          });
        }
      }
      console.log(famigliaFormatted);
      var famiglia = [[
          { name: "codiceFamiglia", label: "Famiglia N.", value: datiAnagrafica.codiceFamiglia },
          { name: "numeroComponenti", label: "Numero componenti", value: datiAnagrafica.famiglia?datiAnagrafica.famiglia.length:1 },
          { name: "componenti", value: displayList(famigliaFormatted), html: true }
        ]
      ];
      // fare schede per matrimonio/divorzio/vedovanza etc
      // vedi dettagli_persona.shtml per le varie schede
      var matrimonio = [];
      if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.matrimonio) {
        var datiMatrimonio = datiAnagrafica.datiStatoCivile.matrimonio;
        matrimonio.push([
          { name: "coniuge", value: (datiMatrimonio.coniuge.cognome?datiMatrimonio.coniuge.cognome:"")+" "+(datiMatrimonio.coniuge.nome?datiMatrimonio.coniuge.nome:"") },
          { name: "comune", value: datiMatrimonio.comune },
          { name: "dataMatrimonio", name: "Data matrimonio", value: datiMatrimonio.data },
        ]);
      }
      if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.divorzio) {
        var datiDivorzio = datiAnagrafica.datiStatoCivile.divorzio;
        matrimonio.push([
          { name: "dataDivorzio", name: "Data divorzio", value: datiDivorzio.data },
          { name: "tribunale", value: datiDivorzio.tribunale },
          { name: "", value: "" },
        ]);
      }
      var autocertificazioni = [];
      if(test) {
        var testList = [{
          preText: "Nome documento ",
          text: <span>scarica documento <i className='fa fa-download'></i></span>,
          postText: todo("da dove si prende?","danger"),
          url: dominio+"/autocertificazionei?codice_fiscale="+datiAnagrafica.codiceFiscale+"&nome=Nome documento"
        }]
        autocertificazioni = [[
          { name:"listaAutocertificazioni", value: displayList(testList), html: true }
        ]]
        for (var componente in famiglia) {
          famigliaFormatted.push({
            preText: null,
            text: datiAnagrafica.famiglia[componente].cognome+" "+datiAnagrafica.famiglia[componente].nome,
            postText: <span>{datiAnagrafica.famiglia[componente].codiceRelazioneParentelaANPR}{todo("da dove si prende la descrizione?")}</span>, // prendere da apposita tabella, ordinare per codice
            url: dominio+"/dettagli_persona?codice_fiscale="+datiAnagrafica.famiglia[componente].codiceFiscale
          })
        }
      }
      var elettorale = [[
          { name: "statusElettore", label: "Stato elettore", value: todo("da dove si prende?","danger") },
          { name: "iscrizione", value: todo("da dove si prende?","danger") },
          { name: "fascicolo", value: todo("da dove si prende?","danger") }
        ],[
          { name: "numeroDiGenerale", label: "Numero di generale", value: todo("da dove si prende?","danger") },
          { name: "sezioneDiAppartenenza", label: "Sezione di appartenenza", value: todo("da dove si prende?","danger") },
          { name: "sezionale", value: todo("da dove si prende?","danger") }
        ]
      ];

      returnVal =       <div itemID="app_tributi">
      <h4>Dettagli persona</h4>
      {datiAnagrafica?
        <div className="form-horizontal">{displayForm(datiCittadino)}</div>:<p>Caricamento dati utente...</p>
      }   
      
      <p></p>

      <div className={datiAnagrafica?"":"hide"}>
        
        <ul className="nav nav-tabs">
          <li role="presentation" className="active"><a href="#anagrafica" aria-controls="anagrafica" role="tab" data-toggle="anagrafica">Scheda Anagrafica</a></li>
          <li role="presentation"><a href="#matrimonio" aria-controls="matrimonio" role="tab" data-toggle="matrimonio">Matrimonio</a></li>
          <li role="presentation"><a href="#elettorale" aria-controls="elettorale" role="tab" data-toggle="elettorale">Elettorale</a></li>
          <li role="presentation"><a href="#documenti" aria-controls="documenti" role="tab" data-toggle="documenti">Documenti</a></li>
          <li role="presentation"><a href="#famiglia" aria-controls="famiglia" role="tab" data-toggle="famiglia">Famiglia</a></li>
          <li role="presentation"><a href="#autocertificazioni" aria-controls="autocertificazioni" role="tab" data-toggle="autocertificazioni">Autocertificazioni</a></li>
        </ul>
        
        <div className="tab-content">
        
          <div role="tabpanel" className="tab-pane" id="anagrafica">
            <div className="panel panel-default panel-tabbed">
              <div className="panel-body form-horizontal">
                {displayForm(anagrafica)}
              </div>
            </div>
          </div>
          
          <div role="tabpanel" className="tab-pane" id="matrimonio">
            <div className="panel panel-default panel-tabbed">
              <div className="panel-body form-horizontal">
                {displayForm(matrimonio)}
              </div>
            </div>
          </div>
          
          <div role="tabpanel" className="tab-pane" id="elettorale">
            <div className="panel panel-default panel-tabbed">
              <div className="panel-body form-horizontal">
                {displayForm(elettorale)}
              </div>
            </div>
          </div>
          
          <div role="tabpanel" className="tab-pane" id="documenti">
            <div className="panel panel-default panel-tabbed">
              <div className="panel-body form-horizontal">
                {displayForm(documenti)}
              </div>
            </div>
          </div>
          
          <div role="tabpanel" className="tab-pane" id="famiglia">
            <div className="panel panel-default panel-tabbed">
              <div className="panel-body form-horizontal">
                {displayForm(famiglia)}
              </div>
            </div>
          </div>
          
          <div role="tabpanel" className="tab-pane" id="autocertificazioni">
            <div className="panel panel-default panel-tabbed">
              <div className="panel-body form-horizontal">
                {displayForm(autocertificazioni)}
              </div>
            </div>
          </div>
        
        </div>

      </div>

      {test?<pre style={{"whiteSpace": "break-spaces"}}><code>{datiAnagrafica?JSON.stringify(datiAnagrafica, null, 2):""}</code></pre>:""}

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

  $(".tab-pane").hide();  
  
  $("#anagrafica").show();
  
  $('.nav-tabs a').on('click',function (e) {
    e.preventDefault();
    $(".tab-pane").hide();
    $(".nav-tabs li").removeClass("active");
    $("#"+$(this).data("toggle")).show()
    $(this).parent().addClass("active");
  })
}