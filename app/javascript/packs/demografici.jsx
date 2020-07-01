// file da includere in tutte le pagine

demograficiData.dominio = window.location.protocol+"//"+window.location.hostname+(window.location.port!=""?":"+window.location.port:"");
$(document).ready(function(){
  var $links = $("#topbar").find(".row");
  $links.find("div").last().remove();
  $links.find("div").first().removeClass("col-lg-offset-3").removeClass("col-md-offset-3");
  $links.append('<div class="col-lg-2 col-md-2 text-center"><a href="/portale" title="Sezione Privata">CIAO<br>'+$("#nome_utente").text()+'</a></div>');
  $links.append('<div class="col-lg-1 col-md-1 logout_link"><a href="logout" title="Logout"><span class="glyphicon glyphicon-log-out" aria-hidden="true"></span></a></div>');
});