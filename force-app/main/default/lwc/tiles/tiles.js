import { LightningElement, api } from 'lwc';

export default class Tiles extends LightningElement {
    
    _records;
    _fieldsToDisplay;
    showTiles;

    @api
    get records(){
        return this._records;
    }
    set records(val) {
        this._records = val;
        this.apiProprtiesReady();
    }

    @api
    get fieldsToDisplay(){
        return this._fieldsToDisplay;
    }
    set fieldsToDisplay(val) {
        this._fieldsToDisplay = val;
        this.apiProprtiesReady();
    }
    
    @api objectName;
    @api tileTitle;
    @api selectedRecId;
    runningRecords = [];

    apiProprtiesReady(){
        if(this._fieldsToDisplay && this._records){
            this.setRecords();
        }
    }

    setRecords(){
        let newRecId;
        if(!this._records) return;
        let apiFields = Object.getOwnPropertyNames(this._fieldsToDisplay);
        // records to run on from new loop
        let Ids = this.runningRecords.map(({ Id }) => Id);
        if(this.runningRecords.length > this._records.length){ // remove an item 
            this.runningRecords = this.runningRecords.filter(rec => { 
				return rec.Id != this.selectedRecId;
			});
            return;
        }
        this._records = this._records.filter((ele) => {
            return !Ids.includes(ele.Id);
        });
        console.log(JSON.stringify(this._records));
        if(this._records.length == 1) newRecId = this._records[0].Id// new record was selected

        // set label on the the record fields 
        this._records.forEach(rec => {
            let curRec =  [...Object.keys(rec).map(key => {
                let fieldLabel = apiFields.includes(key) ? this._fieldsToDisplay[key] : key;
                let fieldValue = rec[key];
                if(typeof fieldValue == 'object' && fieldValue != null) fieldValue = fieldValue.Name; //lookups
                return {label: fieldLabel, value: fieldValue, displayField : apiFields.includes(key)};
            })];
            //fields with null value
            apiFields.forEach(ele => {
                if(!rec.hasOwnProperty(ele)) curRec.push({label: this._fieldsToDisplay[ele], value: '', displayField : true});
            });
            let curRecWithId = {Id : rec.Id, fields : curRec}; // {Id : 999, fields : [{"label":"Id","value":"0030500000PuYAqAAN","displayField":false}]};
            this.runningRecords.unshift(curRecWithId); 
        });
        if(this.runningRecords.length > 0) this.showTiles = true;
        //select tile if needed
        if(newRecId){
            setTimeout(() => {
                this.clearoutCheckedRecords();
                this.checkRecord(newRecId);
                this.addBorder(newRecId);
            });
        }
    }

    sendOutRecId(recId){
        this.dispatchEvent(new CustomEvent('tileselect', {
            detail:recId
        }));
    }

    handleSelectedItem(event){
        this.sendOutRecId(event.target.value);
        this.addBorder(event.target.value);
    }

    @api addBorder(recId){
        //remove borders from 
        let elements = this.template.querySelectorAll(".slds-box");
        elements.forEach(ele => {
            ele.classList.remove('bold-border');
        });
        // add class to selected tile
        let element = this.template.querySelector('div[data-id="'+ recId +'"]');
        if(element) element.classList.add('bold-border');
    }

    checkRadioButton(event){
       let recId =  event.currentTarget.dataset.id;
       console.log(recId);
       this.addBorder(recId);
       this.checkRecord(recId);
       this.sendOutRecId(recId);
    }

    @api clearoutCheckedRecords(){
        let elements = this.template.querySelectorAll('input[data-name="'+ this.objectName +'"]'); 
        elements.forEach(ele => {
            if(ele.checked) ele.checked = false;
        });
    }
    
    @api checkRecord(recId){
        this.clearoutCheckedRecords();
        let ele = this.template.querySelector('input[data-id="' + recId + '"]');	
        if(ele) ele.checked = true;
    }

    mouseOverTile(event) {
        let tile = event.target.closest('.slds-box');
        tile.classList.remove('on-tile-out'); 
        tile.classList.add('on-tile-over'); 
    }

    mouseOutOfTile(event) {
    let tile = event.target.closest('.slds-box');
    tile.classList.remove('on-tile-over'); 
    tile.classList.add('on-tile-out'); 
    }

}