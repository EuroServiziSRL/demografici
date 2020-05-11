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

function displayForm(rows, width) {
  // console.log(cell);
  if( typeof(width) == "undefined" ) { width = 12; }
  var rowsHtml = []
  
  for(var r in rows) {
    var fieldsHtml = [];
    var fields = rows[r];
    var fieldSize = width/fields.length;
    var labelSize = Math.floor(fieldSize/3);
    var valueSize = fieldSize-labelSize;
    for(var f in fields) {
      if( typeof(fields[f].labelSize) == "undefined" ) { fields[f].labelSize = labelSize; }
      if( typeof(fields[f].valueSize) == "undefined" ) { fields[f].valueSize = valueSize; }
      if( typeof(fields[f].label) == "undefined" ) { fields[f].label = ucfirst(fields[f].name); }
      var labelClass = "col-lg-"+fields[f].labelSize+" control-label";
      var valueClass = "col-lg-"+fields[f].valueSize;
      fieldsHtml.push(<label htmlFor={fields[f].name} className={labelClass}>{fields[f].label}</label>)
      if(fields[f].html) {
        fieldsHtml.push(<div className={valueClass} id={fields[f].name}>{fields[f].value}</div>)
      } else {
        fieldsHtml.push(<div className={valueClass}><p id={fields[f].name} className="form-control-static">{fields[f].value}</p></div>)
      }
              
    }
    rowsHtml.push(<div className="form-group"> {fieldsHtml} </div>)
  }
  return rowsHtml;
}

function displayFamiglia(famiglia) {
  var listItems = []
  if(famiglia) {
    listItems.push(famiglia.map((membro, index) => <a  className="list-group-item" key={index.toString()} href={dominio+"/dettagli_persona?codice_fiscale="+membro.codiceFiscale}>{membro.cognome} {membro.nome} <span className="badge">{membro.codiceRelazioneParentelaANPR+" (da trovare descrizione)"}</span></a>  ));
  }
  return <div className="list-group">{listItems}</div>
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
    console.log(datiAnagrafica);
    var returnVal = <div className="alert alert-warning">Dati contribuente non presenti nel sistema</div>
    if(datiAnagrafica!=null) {
      var datiCittadino = [[
          { name: "nominativo", value: datiAnagrafica.cognome+" "+datiAnagrafica.nome },
          { name: "indirizzo", value: datiAnagrafica.indirizzo },
        ], [
          { name: "status", value: datiAnagrafica.posizioneAnagrafica },
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
          { name: "codiceIstatComuneNascitaItaliano", label: "Comune di nascita", value: datiAnagrafica.codiceIstatComuneNascitaItaliano+" (da trovare descrizione)" },
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
      var documenti = [[
          { name: "numero", value: datiAnagrafica.numero },
          { name: "stato", value: "manca l'informazione" },
          { name: "dataRilascio", label: "In data", value: datiAnagrafica.dataRilascio },
          { name: "scadenza", value: "manca l'informazione" },
        ]
      ];
      var famiglia = [[
          { name: "codiceFamiglia", label: "Famiglia N.", value: datiAnagrafica.codiceFamiglia },
          { name: "numeroComponenti", label: "Numero componenti", value: datiAnagrafica.famiglia?datiAnagrafica.famiglia.length:1 },
          { name: "componenti", value: displayFamiglia(datiAnagrafica.famiglia), html: true }
        ]
      ];
      var matrimonio = [];
      if(datiAnagrafica.datiStatoCivile && datiAnagrafica.datiStatoCivile.matrimonio) {
        var datiMatrimonio = datiAnagrafica.datiStatoCivile.matrimonio;
        matrimonio.push([
          { name: "coniuge", value: (datiMatrimonio.coniuge.cognome?datiMatrimonio.coniuge.cognome:"")+" "+(datiMatrimonio.coniuge.nome?datiMatrimonio.coniuge.nome:"") },
          { name: "comune", value: datiMatrimonio.comune },
          { name: "dataMatrimonio", value: datiMatrimonio.data },
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
      var elettorale = [];

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
  $links.append('<div class="col-lg-2 col-md-2 text-center"><a href="'+$("#dominio_portale").text()+'/" title="Sezione Privata">CIAO<br>'+$("#nome").text()+'</a></div>');
  $links.append('<div class="col-lg-1 col-md-1 logout_link"><a href="'+$("#dominio_portale").text()+'/autenticazione/logout" title="Logout"><span class="glyphicon glyphicon-log-out" aria-hidden="true"></span></a></div>');
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