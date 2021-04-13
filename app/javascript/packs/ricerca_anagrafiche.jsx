window.appType = "external";

import React from 'react';
import ReactDOM from 'react-dom';

import BootstrapTable from 'react-bootstrap-table-next';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faCircleNotch } from '@fortawesome/free-solid-svg-icons'
import { linkAnagraficaFormatter } from './demografici'
import { posizioneAnagraficaFormatter } from './demografici'
import { AsyncTypeahead } from 'react-bootstrap-typeahead';

class RicercaAnagrafiche extends React.Component{
  typeahead = null;

  state = {
    token:false,
    error:false, 
    error_message:false,  
    dati: undefined,   
    dataNascitaDal: undefined, 
    dataNascitaAl: undefined,
    defaultVia: [],
    vieLoading: false,
    loading: undefined,
    csrf: "",
    page: 1,
    enableSearch: false
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
    var selectedVia = [];
    if(demograficiData.searchParams.idStrada!=null && demograficiData.searchParams.idStrada!="" && demograficiData.searchParams.nomeVia !=null &&  demograficiData.searchParams.nomeVia!="") {
      selectedVia.push(
        {
          "id": demograficiData.searchParams.idStrada,
          "descrizione": demograficiData.searchParams.nomeVia
        }
      );
    }
    console.log("set selectedvia to",selectedVia);
    this.state.defaultVia = selectedVia;
    
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
        if(typeof(demograficiData.searchParams)!="undefined" && Object.entries(demograficiData.searchParams).filter(([k,v],i)=>!!v).length>0) {
          $("#sessoM").prop("checked", demograficiData.searchParams.sesso=="M");
          $("#sessoF").prop("checked", demograficiData.searchParams.sesso=="F");
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
    $('#formRicercaAnagrafiche input, #formRicercaAnagrafiche button, #formRicercaAnagrafiche select, #formRicercaAnagrafiche radio').each(function(){
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
    state.enableSearch = false;
    // state.dati = undefined;
    self.setState(state);
    console.log("ricercaAnagrafiche...");    
    self.disableForm(true,false); 
    var serialized = $('#formRicercaAnagrafiche').serialize();
    self.disableForm(true,true);
    console.log("idStrada",$("#idStrada").val());
    console.log("nomeVia",$("#nomeVia").val());
    $.get(demograficiData.dominio+"/ricerca_anagrafiche_individui", serialized).done(function( response ) {
      console.log("ricercaAnagrafiche response is loaded");
      console.log(response);
      if(response.hasError) {
        console.log("response error");
      } else {
        console.log("response ok");
        state = self.state;
        state.dati = undefined;
        state.error = false;
        state.debug = response;
        self.setState(state);
        if(!response.errore) {
          console.log("response doesn't have errore: ",response);
          state.dati = response.data;
          state.debug = response;
        } else {
          console.log("response has errore: ",response);
          state.error = true;
          state.error_message = response.messaggio_errore;
        }
        state.loading = false;
        state.enableSearch = true;
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
    var state = this.state;
    state.enableSearch = false;
    this.setState(state);

    var $submit = $("#formRicercaAnagrafiche").find("input[type=submit]");
    $submit.parent().parent().next().hide();
    $("#formRicercaAnagrafiche").find("input[type=text],input[type=date],input[name=idStrada],input[name=nomeVia],input[type=radio]:checked,select").each(function(){
      var value = $(this).val()?$(this).val().trim():"";
      var name = $(this).attr("name");
      var error = false;
      console.log("checking field "+name,value);
      demograficiData.searchParams[name] = value;
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
      } else if (name=="idStrada" && value == "") {
        demograficiData.searchParams[name] = state.defaultVia.length>0?state.defaultVia[0].id:'';
        if(state.defaultVia.length>0) {
          searchValues.push(state.defaultVia[0].id);        
        }  
      } else if ( value !== "" && typeof(name)!="undefined") {
        console.log("search value for "+name+" is valid", value);
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
      var state = this.state;
      state.enableSearch = false;
      this.setState(state);
      if($submit.parent().parent().next().find(".error").length < 1) {
        $('<div class="form-group"><div class="col-lg-offset-2 col-lg-4"><p class="text-danger error"></p></div></div>').insertAfter($submit.parent().parent());
      }
      if(formError !== "") {
        $submit.parent().parent().next().find(".error").html(formError); 
        $submit.parent().parent().next().show();
      }
    } else {
      $("#buttonClear").removeAttr("disabled");
      if(searchValues.length>0) {
        var state = this.state;
        state.enableSearch = true;
        this.setState(state);
      }
    }
  }  

  ricercaVie(query) {
    console.log("ricercaVie query", query);
    var self = this;
    self.state.vieLoading = true;
    this.setState(self.state);

    $.get(demograficiData.dominio+"/ricerca_indirizzi?indirizzo="+query).done(function( response ) {
      console.log("got response", response);
      self.state.vieLoading = false;
      self.state.listaVie = response;
      self.setState(self.state);
    });
  }

  selezionaVia(selectedOptions) {
    console.log("selezionaVia selectedOptions",selectedOptions);
    var state = this.state;
    state.defaultVia = selectedOptions;
    state.listaVie = selectedOptions;
    this.setState(state);
    this.validateForm();
    // if(selectedOptions!=null && selectedOptions.length>0) {
    //   console.log("setting idStrada to ", selectedOptions[0].id+"");
    //   $("#idStrada").val(selectedOptions[0].id+"");
    //   console.log("setting nomeVia to ", selectedOptions[0].descrizione);
    //   $("#nomeVia").val(selectedOptions[0].descrizione);
    // } else {
    //   $("#idStrada").val("");
    //   $("#nomeVia").val("");
    // }
  }

  validaVia(event) {
    console.log("validaVia (blur) event",event);
    if(typeof(this.state.listaVie)=="undefined" || typeof(this.state.defaultVia)=="undefined" || this.state.listaVie.length<1 || this.state.defaultVia.length<1) {
      console.log("this.typeahead",this.typeahead);
      this.typeahead.clear();
    }
    this.validateForm();
    // var state = this.state;
    // state.defaultVia = selectedOptions;
    // state.listaVie = selectedOptions;
    // this.setState(state);
    // this.validateForm()
    // if(selectedOptions!=null && selectedOptions.length>0) {
    //   console.log("setting idStrada to ", selectedOptions[0].id+"");
    //   $("#idStrada").val(selectedOptions[0].id+"");
    //   console.log("setting nomeVia to ", selectedOptions[0].descrizione);
    //   $("#nomeVia").val(selectedOptions[0].descrizione);
    // } else {
    //   $("#idStrada").val("");
    //   $("#nomeVia").val("");
    // }
  }

  clearForm() {
    console.log("clearForm");
    $("#formRicercaAnagrafiche").find("input[type=text],input[type=date],input[type=radio]:checked,select").each(function(){
      if($(this).attr("type")=="radio") {
        $(this).prop("checked", false);
      } else {
        $(this).val(null);
      }
    });
    $("#idStrada").val(null);
    $("#nomeVia").val(null);
    $("#indirizzo").find(".rbt-input-main").val("");
    var state = this.state;
    state.defaultVia = [];
    state.dati = undefined;
    state.enableSearch = true;
    state.page = 1;
    demograficiData.searchParams.page = 1;

    state.loading = undefined;
    this.setState(state);
    console.log("state changed to",this.state);
    $("#page").val(1);
    console.log("disabling buttonClear");
    $("#buttonClear").attr("disabled","disabled");
    this.validateForm();
  }

  render() {
    console.log("rendering ricerca_anagrafiche");
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
    console.log("this.state:",this.state);
    console.log("startDate is ");
    var startDate = this.state.dataNascitaDal
    console.log(startDate);
    console.log("endDate is ");
    var endDate = this.state.dataNascitaAl
    console.log(endDate);
    console.log("selected cittadinanza ", demograficiData.searchParams.cittadinanza);

    var selectCittadinanze = []
    for(var e in demograficiData.cittadinanze) {
      var cittadinanzaString = demograficiData.cittadinanze[e].Cittadinanza;
      if(cittadinanzaString!= demograficiData.cittadinanze[e].Descrizione) {
        cittadinanzaString = demograficiData.cittadinanze[e].Descrizione+' ('+demograficiData.cittadinanze[e].Cittadinanza+')';
      }
      if(demograficiData.cittadinanze[e].Cittadinanza == "ITALIANA") {
        selectCittadinanze.unshift(<option key={demograficiData.cittadinanze[e].Id} value={demograficiData.cittadinanze[e].Id}>{cittadinanzaString}</option>);
      } else {
        selectCittadinanze.push(<option key={demograficiData.cittadinanze[e].Id} value={demograficiData.cittadinanze[e].Id}>{cittadinanzaString}</option>);
      }
    }
    selectCittadinanze.unshift(<option key="none" value=""></option>)
    var cittadinanzaDefault = parseInt(demograficiData.searchParams.cittadinanza);
    if(isNaN(cittadinanzaDefault)) {cittadinanzaDefault=null;}

    var selectStatiAnagrafici = []
    selectStatiAnagrafici.push(<option key="empty" value=""></option>);
    for(var e in demograficiData.statiAnagrafici) {
      selectStatiAnagrafici.push(<option key={demograficiData.statiAnagrafici[e]} value={e}>{demograficiData.statiAnagrafici[e]}</option>);
    }
    var statoAnagraficoDefault = demograficiData.searchParams.statoAnagrafico;
    if(!statoAnagraficoDefault) {statoAnagraficoDefault=null;}

    var content = <div>
      {this.state.csrf=="" ? <div className="row"><div className="col-lg-12"><p className="alert alert-info">Caricamento...</p></div></div> : <><form method="post" action="" className="row form-ricerca form-horizontal" onSubmit={this.ricercaAnagrafiche.bind(this)} id="formRicercaAnagrafiche">
        <div className="col-lg-12 col-md-12 col-sm-12 col-xs-12">
          <h3>Ricerca anagrafiche</h3>
          <div className="panel panel-default col-lg-12">

            <div className="form-group">
              <input type="hidden" id="page" name="pageNumber" value={this.state.page} defaultValue={demograficiData.searchParams.page}/>
              <input type="hidden" name="idStrada" id="idStrada" value={this.state.defaultVia.length>0?this.state.defaultVia[0].id:''}/>
              <input type="hidden" name="nomeVia" id="nomeVia" value={this.state.defaultVia.length>0?this.state.defaultVia[0].descrizione:''}/>
              <input type="hidden" name="authenticity_token" value={this.state.csrf}/>
            </div>

            <div className="form-group">
              {demograficiData.cittadino?<></>:<><label htmlFor="cognomeNome" className="col-lg-2 control-label">Cognome/Nome</label>
              <div className="col-lg-4" id="cognomeNome">
                <input type="text" onChange={this.validateForm.bind(this)} onBlur={this.validateForm.bind(this)} className="form-control" name="cognomeNome" id="cognomeNome" defaultValue={demograficiData.searchParams.cognomeNome}/>
              </div></>}
              <label htmlFor="codiceFiscale" className="col-lg-2 control-label">Codice Fiscale</label>
              <div className="col-lg-4" id="codiceFiscale">
                <input type="text" onChange={this.validateForm.bind(this)} onBlur={this.validateForm.bind(this)} className="form-control" name="codiceFiscale" id="codiceFiscale" defaultValue={demograficiData.searchParams.codiceFiscale}/>
              </div>
            </div>

            {demograficiData.ricercaEstesa?<><div className="form-group">
              <label htmlFor="cittadinanza" className="col-lg-2 control-label">Cittadinanza</label>
              <div className="col-lg-4" id="cittadinanza">
                <select className="form-control" defaultValue={cittadinanzaDefault} name="idCittadinanza" onChange={this.validateForm.bind(this)}>{selectCittadinanze}</select>
              </div>
              <label htmlFor="sesso" className="col-lg-2 control-label">Sesso</label>
              <div className="col-lg-4" id="sesso">
                <label className="radio-inline">
                  <input type="radio" onChange={this.validateForm.bind(this)} onBlur={this.validateForm.bind(this)} name="sesso" id="sessoM" defaultValue="M"/> maschio
                </label>
                <label className="radio-inline">
                  <input type="radio" onChange={this.validateForm.bind(this)} onBlur={this.validateForm.bind(this)} name="sesso" id="sessoF" defaultValue="F"/> femmina
                </label>
              </div>
            </div> 
            
            <div className="form-group">
              <label htmlFor="dataNascitaDal" className="col-lg-2 control-label">Data di nascita</label>
              <div className="col-lg-4" id="dataNascitaDal">
                <input type="date" onChange={this.validateForm.bind(this)} onBlur={this.validateForm.bind(this)} className="form-control form-control-datetime" name="dataNascitaDal" id="dataNascitaDal" defaultValue={demograficiData.searchParams.dataNascitaDal}/>
              </div>
              <label htmlFor="dataNascitaAl" className="col-lg-2 control-label">al</label>
              <div className="col-lg-4" id="dataNascitaAl">
                <input type="date" className="form-control form-control-datetime" name="dataNascitaAl" id="dataNascitaAl" onChange={this.validateForm.bind(this)} onBlur={this.validateForm.bind(this)} defaultValue={demograficiData.searchParams.dataNascitaAl}/>
              </div>
            </div>
            
            <div className="form-group">
              <label htmlFor="indirizzo" className="col-lg-2 control-label">Indirizzo (senza toponimo)</label>
              <div className="col-lg-4" id="indirizzo">
              <AsyncTypeahead
                ref={(ref) => this.typeahead = ref}
                id="typeaheadVie"
                isLoading={this.state.vieLoading}
                labelKey={(option) => `${option.descrizione}`}
                name="typeaheadVie"
                minLength={3}
                onSearch={this.ricercaVie.bind(this)}
                options={this.state.listaVie}
                onChange={this.selezionaVia.bind(this)}
                onBlur={this.validaVia.bind(this)}
                selected={this.state.defaultVia}
                promptText="Inizia a scrivere per cercare..."
                searchText="Caricamento..."
                emptyLabel="Nessun risultato"
              />
              </div>
              <label htmlFor="statoAnagrafico" className="col-lg-2 control-label">Stato anagrafico</label>
              <div className="col-lg-4" id="statoAnagrafico">
                <select className="form-control" defaultValue={statoAnagraficoDefault} name="statoAnagrafico" onChange={this.validateForm.bind(this)}>{selectStatiAnagrafici}</select>
              </div>
            </div>
            
            </>:<></>}            
            
            <div className="form-group">
              <div className="col-lg-10 col-lg-offset-2" id="indirizzo">
                <input type="submit" name="invia" id="buttonSearch" className="btn btn-primary mr10" disabled={!this.state.enableSearch} value="Cerca" title="Specifica almeno un criterio di ricerca"/>
                <button type="button" className="btn btn-default" id="buttonClear" onClick={this.clearForm.bind(this)}>Cancella</button>
              </div>
            </div>
            
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
            {demograficiData.cittadino&&demograficiData.residente?<a className="btn btn-default ml10" href="/self">Torna alla tua anagrafica</a>:""}
            {/* <a className="btn btn-default ml10" href="/self">Torna alla tua anagrafica</a> */}
          </div>
        </div>
      </div>
        
      {demograficiData.test?<pre style={{"whiteSpace": "break-spaces"}}><code>{this.state.debug?JSON.stringify(this.state.debug, null, 2):""}</code></pre>:""}

    </div>
    // this.validateForm()
    return content;
  }
}

if(document.getElementById('app_demografici_container') !== null){
  ReactDOM.render(<RicercaAnagrafiche />, document.getElementById('app_demografici_container') );
}