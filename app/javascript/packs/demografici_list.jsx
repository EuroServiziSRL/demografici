import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faDownload } from '@fortawesome/free-solid-svg-icons'
import { hash } from './demografici'

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
    // console.log("rendering DemograficiList");
    // console.log("list");
    // console.log(this.list);
    // console.log("linked");
    // console.log(this.linked);
    // console.log("nostyle");
    // console.log(this.nostyle);
    var listItems = [];
    var html;
    var classNameLi = 'list-group-item';
    var classNameUl = 'list-group';
    if(this.nostyle) {
      classNameLi = 'btn btn-list';
      classNameUl = '';
    }
    if(this.list && this.list[0]) {
      if(this.linked) {
        listItems.push(this.list.map((item, index) => <span className={classNameLi} key={item.text+index.toString()}><a href={item.url}>{item.preText?<span>{item.preText}</span> :""}{typeof(item.text.toLowerCase)=="function"&&item.text.toLowerCase().indexOf("scarica")>-1?<span><FontAwesomeIcon icon={faDownload}/></span>:item.text}{item.postText? <span className="badge">{item.postText}</span>:""}</a></span> ));
      } else {
        listItems.push(this.list.map((item, index) => <li className={classNameLi} key={item.text+index.toString()}>{item.preText?<span>{item.preText}</span> :""}<a href={item.url}>{typeof(item.text.toLowerCase)=="function"&&item.text.toLowerCase().indexOf("scarica")>-1?<span><FontAwesomeIcon icon={faDownload}/></span>:item.text}{item.postText? <span className="badge">{item.postText}</span>:""}</a></li>  ));
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
export {DemograficiList};