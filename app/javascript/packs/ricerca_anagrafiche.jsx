window.appType = "external";

import React, { useState } from 'react';
import ReactDOM from 'react-dom';

import Select from 'react-select';
import BootstrapTable from 'react-bootstrap-table-next';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faCircleNotch } from '@fortawesome/free-solid-svg-icons'
// import DatePicker from 'react-datepicker';
// import it from 'date-fns/locale/it';
demograficiData.descrizioniStatus = {"D":"DECEDUTO", "R":"RESIDENTE", "A":"RESIDENTE AIRE", "I":"IRREPERIBILE", "E":"EMIGRATO"}


function ucfirst(str){
  return str?str.replace(/(\b)([a-zA-Z])/,
    function(firstLetter){
      return   firstLetter.toUpperCase();
    }):"";
}

function linkAnagraficaFormatter(cell) {
  return  <span dangerouslySetInnerHTML={ {__html: cell} } />
} 

function posizioneAnagraficaFormatter(cell) {
  return demograficiData.descrizioniStatus[cell]
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

class RicercaAnagrafiche extends React.Component{

  state = {
    token:false,
    error:false, 
    error_message:false,  
    dati: undefined,   
    dataNascitaDal: undefined, 
    dataNascitaAl: undefined,
    loading: undefined,
    csrf: "",
    page: 1
  } 

  columns = [
    { dataField: "codiceFiscale", text: "Codice fiscale", formatter: linkAnagraficaFormatter },
    { dataField: "nome", text: "Nome" },
    { dataField: "cognome", text: "Cognome" },
    { dataField: "descrizioneCittadinanza", text: "Cittadinanza" },
    { dataField: "sesso", text: "Sesso" },
    { dataField: "dataNascita", text: "Data di nascita" },
    { dataField: "indirizzo", text: "Indirizzo" },
    { dataField: "posizioneAnagrafica", text: "Status", formatter: posizioneAnagraficaFormatter },
    // { dataField: "statoCivile", text: "statoCivile" },
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
        // self.ricercaAnagrafiche();
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

  disableForm(disable, force) {
    $('#formRicercaAnagrafiche input, #formRicercaAnagrafiche select, #formRicercaAnagrafiche radio').each(function(){
      if(($(this).val()=="" && disable)||force) {
        $(this).attr("disabled","true")
      } else {
        $(this).removeAttr("disabled")
      }
    });
  }

  ricercaAnagrafiche(e) {
    console.log(e);
    if(e){e.preventDefault();}
    var self = this;
    var state = self.state;
    state.loading = true;
    // state.dati = undefined;
    self.setState(state);
    console.log("ricercaAnagrafiche...");    
    self.disableForm(true,false); 
    var serialized = $('#formRicercaAnagrafiche').serialize();
    self.disableForm(true,true);
    $.get(demograficiData.dominio+"/ricerca_anagrafiche_individui", serialized).done(function( response ) {
      console.log("ricercaAnagrafiche response is loaded");
      console.log(response);
      if(response.hasError) {
        console.log("response error");
      } else {
        state = self.state;
        state.dati = undefined;
        state.error = false;
        state.debug = response;
        self.setState(state);
        if(!response.errore) {
          console.log(response);
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
        self.disableForm(false,false);
      }
    }).fail(function(response) {
      console.log("ricercaAnagrafiche fail!");
      console.log(response);
      var state = self.state;
      state.dati = undefined;
      state.error = true;
      state.error_message = "Si è verificato un errore generico durante l'interrogazione dati.";
      state.loading = false;
      self.setState(state);
      self.disableForm(false,false);
    });
  }

  goToPage(number) {
    var state = this.state;
    state.page = number;
    this.setState(state);
    $("#page").val(this.state.page);
    scrollToElement($(".table-header"))
    this.ricercaAnagrafiche()
  }

  prevPage() {
    this.goToPage(this.state.page==1?1:this.state.page-1)
  }

  nextPage() {
    this.goToPage(this.state.page+1)
  }

  setStartDate = date =>  {
    console.log("start date changed!");
    console.log(date);
    var state = this.state;
    state.dataNascitaDal = date;
    this.setState(state);
  };

  setEndDate() {
    console.log("end date changed!");
    // console.log(date);
    // var state = this.state;
    // state.dataNascitaAl = date;
    // this.setState(state);
  };

  render() {
    console.log("rendering");
    var loading = <p className="text-center" id={this.state.dati?"loading":""}><FontAwesomeIcon icon={faCircleNotch} size="2x" spin /><span className="sr-only">caricamento...</span></p>;
    var table = "";
    if (this.state.dati && this.state.dati.length > 0) {
      var paginatorLinks = []
      console.log("this.state.dati[0]: ");
      console.log(this.state.dati[0]);
      var lastPage = Math.ceil(this.state.dati[0].paging.totalCount/this.state.dati[0].paging.itemsPerPage);
      console.log("lastPage: "+lastPage);
      var startPaginator = this.state.page-4>0?this.state.page-4:1;
      console.log("startPaginator: "+startPaginator);
      var endPaginator = this.state.page+5<=lastPage?this.state.page+5:lastPage;
      console.log("endPaginator: "+endPaginator);
      if(this.state.page>1) {
        paginatorLinks.push(<button className="btn btn-default" type="button" title={"pagina iniziale"} onClick={() => this.goToPage(1).bind(this)}>&lt;&lt;</button>);
        paginatorLinks.push(<button className="btn btn-default" type="button" title={"pagina precedente"} onClick={this.prevPage.bind(this)}>&lt;</button>);
      }
      if(startPaginator>1) {
        var p = startPaginator-1;
        paginatorLinks.push(<button className="btn btn-default" type="button" title={"pagine precedenti"} onClick={this.goToPage.bind(this,p)}>...</button>);
      }
      for(var p = startPaginator; p < this.state.page; p++) {
        paginatorLinks.push(<button className="btn btn-default" type="button" title={"pagina "+p} onClick={this.goToPage.bind(this,p)}>{p}</button>);
      }
      paginatorLinks.push(<span className="btn btn-primary disabled" type="button" title={"pagina "+p}>{this.state.page}</span>);
      for(var p = this.state.page+1; p < endPaginator; p++) {
        paginatorLinks.push(<button className="btn btn-default" type="button" title={"pagina "+p} onClick={this.goToPage.bind(this,p)}>{p}</button>);
      }
      if(endPaginator<lastPage) {
        var p = endPaginator;
        paginatorLinks.push(<button className="btn btn-default" type="button" title={"pagine successive"} onClick={this.goToPage.bind(this,p)}>...</button>);
      }
      if(this.state.page<lastPage) {
        paginatorLinks.push(<button className="btn btn-default" type="button" title={"pagina successiva"} onClick={this.nextPage.bind(this)}>&gt;</button>);
        paginatorLinks.push(<button className="btn btn-default" type="button" title={"ultima paigna"} onClick={() => this.goToPage(lastPage).bind(this)}>&gt;&gt;</button>);
      }

      table = <div>{this.state.loading==true?loading:""}<div className={"row"+(this.state.loading==true?" transparent":"")}>
        <div className="col-lg-12">
          <BootstrapTable
            id="ricercaAnagrafiche"
            keyField={"codiceCittadino"}
            data={this.state.dati}
            columns={this.columns}
            classes="table-responsive"
            striped
            hover
          />
        </div>
      </div>
      {this.state.loading==true?"":<div className="row">
        <div className="col-lg-12 btn-toolbar mb20">
          <div className="btn-group" role="group">
            <span className="btn">Pagina {this.state.page} di {lastPage}</span>
          </div>
          <div className="btn-group" role="group">
            {paginatorLinks}
          </div>
        </div>
      </div>}
    </div>
    } else if (this.state.loading==true) {
      console.log("loading & not dati");
      table = <div className="row"><div className="col-lg-12">{loading}</div></div>
    } else if (this.state.loading==false && this.state.dati.length < 1) {
      console.log("not loading & not dati");
      table = <div className="row"><div className="col-lg-12"><p className="text-center">Nessun risultato</p></div></div>
    } else if (this.state.loading==undefined && this.state.csrf!="") {
      console.log("loading undefined?");
      table = <div className="row"><div className="col-lg-12"><p className="alert alert-info">Effettua una ricerca per visualizzare le anagrafiche.</p></div></div>
    }
    console.log("startDate is ");
    var startDate = this.state.dataNascitaDal
    console.log(startDate);
    console.log("endDate is ");
    var endDate = this.state.dataNascitaAl
    console.log(endDate);

    // var selectCittadinanze = []
    // selectCittadinanze.push(<option value=""></option>)
    // for(var e in demograficiData.cittadinanze) {
    //   selectCittadinanze.push(<option value={demograficiData.esenzioniBollo[e].id}>{demograficiData.esenzioniBollo[e].descrizione}</option>)
    // }
    // selectCittadinanze = <select className="form-control" defaultValue="" name="idCittadinanza">{selectCittadinanze}</select>

    var content = <div>
      {this.state.csrf=="" ? <div className="row"><div className="col-lg-12"><p className="alert alert-info">Caricamento...</p></div></div> : <div className="row form-ricerca form-horizontal"><form method="post" action="" className="col-lg-12 col-md-12 col-sm-12 col-xs-12" onSubmit={this.ricercaAnagrafiche.bind(this)} id="formRicercaAnagrafiche"><h3>Ricerca anagrafiche</h3>
        <div className="panel panel-default">
          <DemograficiForm rows={[
            [
              { name: "", value: <input type="hidden" id="page" name="pageNumber" value={this.state.page}/>, html: true }
            ],
            [
              { name:"cognomeNome", label:"Cognome/Nome", value: <input type="text" className="form-control" name="cognomeNome" id="cognomeNome"/>, html: true },
              { name:"codiceFiscale", label:"Codice Fiscale", value: <input type="text" className="form-control" name="codiceFiscale" id="codiceFiscale"/>, html: true },
            ],
            [
              // TODO capire che id usa
              // { name:"cittadinanza", value:selectCittadinanze, html: true },
              // { name:"cittadinanza", value: <select name="idCittadinanza" className="form-control">
              //   <option></option>
              //   <option value="1">Italiana</option>
              //   <option value="2">Straniera</option>
              //   <option value="3">Straniera paesi U.E.</option>
              //   <option value="4">Straniera paesi dello Spazio Economico Europeo e paesi con accordi di associazione</option>
              //   <option value="5">Straniera paesi non U.E.</option>
              //   <option value="6">Tutte</option>
              // </select>, html: true },
              { name:"sesso", value: <>
              <label className="radio-inline">
                    <input type="radio" name="sesso" id="sessoM" defaultValue="M"/> maschio
                  </label>
                  <label className="radio-inline">
                    <input type="radio" name="sesso" id="sessoF" defaultValue="F"/> femmina
                  </label>
            </>, html: true }
            ]/*,
            [
              { name:"dataNascitaDal", label:"Data di nascita dal", value: <>
              <DatePicker
                selected={startDate}
                onSelect={this.setStartDate}
                onChange={this.setStartDate}
                selectsStart
                startDate={startDate}
                endDate={endDate}
                locale = "it"
              />
              <DatePicker
                selected={endDate}
                onChange={() => this.setEndDate().bind(this)}
                selectsEnd
                startDate={startDate}
                endDate={endDate}
                minDate={startDate}
                locale = "it"
              />
              </>, html: true },
              { name:"dataNascitaAl", label:"al", value: <input type="text" className="form-control" name="dataNascitaAl" id="dataNascitaAl"/>, html: true },
              { name:"indirizzo", value: <input type="text" className="form-control" name="indirizzo" id="indirizzo"/>, html: true }
            ]*/,
            [
              { name:"", value: <input type="submit" name="invia" className="btn btn-default" value="Cerca"/>, html: true },
              { name: "", value: <input type="hidden" name="authenticity_token" value={this.state.csrf}/>, html: true }
            ]
          ]}/>
        </div>
      </form></div>}

      
      {table}

      <div className="bottoni_pagina mb20">
        <div className="row">
          <div className="col-lg-6 col-md-6 col-sm-12 col-xs-12">
            <div className="back">
              <a className="btn" href="/portale">Torna al portale</a>              
            </div>
            <a className="btn btn-default ml10" href="/self">Torna alla tua anagrafica</a>
          </div>
        </div>
      </div>
        
      {demograficiData.test?<pre style={{"whiteSpace": "break-spaces"}}><code>{this.state.debug?JSON.stringify(this.state.debug, null, 2):""}</code></pre>:""}

    </div>
    return content;
  }
}

if(document.getElementById('app_demografici_container') !== null){
  ReactDOM.render(<RicercaAnagrafiche />, document.getElementById('app_demografici_container') );
}