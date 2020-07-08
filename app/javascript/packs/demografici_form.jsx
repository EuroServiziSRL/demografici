import React from 'react';
import { ucfirst } from './demografici'

class DemograficiForm extends React.Component{
  
  cols = 12
  maxLabelCols = 2
  rows = []

  constructor(props){
    super(props);
    // console.log("DemograficiForm received props");
    // console.log(props);
    if( typeof(props.cols) != "undefined" ) { this.cols = props.cols; }
    if( typeof(props.maxLabelCols) != "undefined" ) { this.maxLabelCols = props.maxLabelCols; }
    this.rows = props.rows
    // console.log("constructor end");
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

export {DemograficiForm};