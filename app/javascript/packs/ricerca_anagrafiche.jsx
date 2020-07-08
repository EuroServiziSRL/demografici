window.appType = "external";

import React from 'react';
import ReactDOM from 'react-dom';

import BootstrapTable from 'react-bootstrap-table-next';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faCircleNotch } from '@fortawesome/free-solid-svg-icons'
import { DemograficiForm } from './demografici_form'
import { linkAnagraficaFormatter } from './demografici'
import { posizioneAnagraficaFormatter } from './demografici'

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
    
    console.log("AppDemografici did update");
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
        if(typeof(demograficiData.searchParams)!="undefined" && demograficiData.searchParams.length) {
          self.ricercaAnagrafiche();
        }
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

  validateForm() {
    var searchValues = [];
    var formError = false;
    var $submit = $("#formRicercaAnagrafiche").find("input[type=submit]");
    $submit.parent().parent().next().hide();
    $("#formRicercaAnagrafiche").find("input[type=text],input[type=date],input[type=radio]:checked,select").each(function(){
      var value = $(this).val()?$(this).val().trim():"";
      var error = false;
      $(this).next(".error").hide();
      if ($(this).attr("required") && value === "") {
        error = "questo dato è obbligatorio";
        formError = "";
        if($(this).next(".error").length < 1) {
          $('<p class="text-danger error"></p>').insertAfter($(this));
        }
        $(this).next(".error").html(error).show();
        console.log("formError",formError);
        console.log("error",error);
      } else if ( value !== "") {
        searchValues.push(value);
      }
      // $(this).parent().toggleClass("has-success", error===false);
      $(this).parent().toggleClass("has-error", error!==false);
    });
    console.log("searchValues",searchValues);
    if(!searchValues.length) {
      formError = "è necessario compilare almeno un campo per la ricerca";
    }
    console.log("formError",formError);
    if(formError!==false) {
      $submit.attr("disabled","disabled");
      if($submit.parent().parent().next().find(".error").length < 1) {
        $('<div class="form-group"><div class="col-lg-offset-2 col-lg-4"><p class="text-danger error"></p></div></div>').insertAfter($submit.parent().parent());
      }
      if(formError !== "") {
        $submit.parent().parent().next().find(".error").html(formError); 
        $submit.parent().parent().next().show();
      }
    } else {
      $submit.removeAttr("disabled");
    }
  }  

  clearForm() {
    $("#formRicercaAnagrafiche").find("input[type=text],input[type=radio]:checked,select").each(function(){
      if($(this).attr("type")=="radio") {
        $(this).prop("checked", false);
      } else {
        $(this).val(null);
      }
    });
    this.validateForm();
  }

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
      paginatorLinks.push(<button key="thisPage" className="btn btn-primary disabled" type="button" title={"pagina "+p}>{this.state.page}</button>);
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
    } else if (this.state.loading==false && this.state.dati && this.state.dati.length < 1) {
      console.log("not loading & not dati");
      table = <div className="row"><div className="col-lg-12"><p className="text-center">Nessun risultato</p></div></div>
    } else if (this.state.loading==undefined && this.state.csrf!="") {
      console.log("loading undefined?");
      table = <div className="row"><div className="col-lg-12"><p className="alert alert-info">Effettua una ricerca per visualizzare le anagrafiche.</p></div></div>
    } else if (this.state.loading!==undefined && this.state.dati==undefined) {
      console.log("loading undefined?");
      table = <div className="row"><div className="col-lg-12"><p className="alert alert-danger">Si è verificato un errore generico durante la ricerca. Si prega di riprovare.</p></div></div>
    }
    console.log("startDate is ");
    var startDate = this.state.dataNascitaDal
    console.log(startDate);
    console.log("endDate is ");
    var endDate = this.state.dataNascitaAl
    console.log(endDate);

    var selectCittadinanze = []
    selectCittadinanze.push(<option key="none" value=""></option>)
    for(var e in demograficiData.cittadinanze) {
      selectCittadinanze.push(<option key={demograficiData.cittadinanze[e].id} value={demograficiData.cittadinanze[e].id}>{demograficiData.cittadinanze[e].cittadinanza}</option>)
    }
    selectCittadinanze = <select className="form-control" defaultValue="" name="idCittadinanza">{selectCittadinanze}</select>

    var content = <div>
      {this.state.csrf=="" ? <div className="row"><div className="col-lg-12"><p className="alert alert-info">Caricamento...</p></div></div> : <><form method="post" action="" className="row form-ricerca form-horizontal" onSubmit={this.ricercaAnagrafiche.bind(this)} id="formRicercaAnagrafiche">
        <div className="col-lg-12 col-md-12 col-sm-12 col-xs-12">
          <h3>Ricerca anagrafiche</h3>
          <div className="panel panel-default">
            <DemograficiForm rows={[
              [
                { name: "", value: <input type="hidden" id="page" name="pageNumber" value={this.state.page} defaultValue={demograficiData.searchParams.page}/>, html: true }
              ],
              [
                { name:"cognomeNome", label:"Cognome/Nome", value: <input type="text" onChange={this.validateForm.bind(this)} onBlur={this.validateForm.bind(this)} className="form-control" name="cognomeNome" id="cognomeNome" defaultValue={demograficiData.searchParams.cognomeNome}/>, html: true },
                { name:"codiceFiscale", label:"Codice Fiscale", value: <input type="text" onChange={this.validateForm.bind(this)} onBlur={this.validateForm.bind(this)} className="form-control" name="codiceFiscale" id="codiceFiscale" defaultValue={demograficiData.searchParams.codiceFiscale}/>, html: true },
              ],
              [
                { name:"cittadinanza", value:selectCittadinanze, html: true },
                { name:"sesso", value: <>
                <label className="radio-inline">
                      <input type="radio" onChange={this.validateForm.bind(this)} onBlur={this.validateForm.bind(this)} name="sesso" id="sessoM" defaultValue="M"/> maschio
                    </label>
                    <label className="radio-inline">
                      <input type="radio" onChange={this.validateForm.bind(this)} onBlur={this.validateForm.bind(this)} name="sesso" id="sessoF" defaultValue="F"/> femmina
                    </label>
              </>, html: true }
              ],
              [
                { name:"dataNascitaDal", label:"Data di nascita", value: <input type="date" onChange={this.validateForm.bind(this)} onBlur={this.validateForm.bind(this)} className="form-control form-control-datetime" name="dataNascitaDal" id="dataNascitaDal" defaultValue={demograficiData.searchParams.dataNascitaDal}/>, html: true },
                { name:"dataNascitaAl", label:"al", value: <input type="date" className="form-control form-control-datetime" name="dataNascitaAl" id="dataNascitaAl" onChange={this.validateForm.bind(this)} onBlur={this.validateForm.bind(this)} defaultValue={demograficiData.searchParams.dataNascitaAl}/>, html: true },
              ],
              [
                { name:"", value: <><input type="submit" name="invia" className="btn btn-primary mr10" disabled value="Cerca" title="Specifica almeno un criterio di ricerca"/><button type="button" className="btn btn-default" onClick={this.clearForm.bind(this)}>Cancella</button></>, html: true },
                { name: "", value: <input type="hidden" name="authenticity_token" value={this.state.csrf}/>, html: true }
              ]
            ]}/>
          </div>
        </div>
      </form></>}

      {table}   

      <div className="bottoni_pagina mb20">
        <div className="row">
          <div className="col-lg-6 col-md-6 col-sm-12 col-xs-12">
            <div className="back">
              <a className="btn" href="/portale">Torna al portale</a>              
            </div>
            {/* <a className="btn btn-default ml10" href="/self">Torna alla tua anagrafica</a> */}
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