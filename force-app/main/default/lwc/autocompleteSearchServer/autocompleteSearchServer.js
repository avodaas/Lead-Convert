import { LightningElement, api} from 'lwc';  
import getRecordsForAutocompleteSearch from '@salesforce/apex/AutocompleteSearch.getRecordsForAutocompleteSearch';

export default class AutocompleteSearchServer extends LightningElement {

	noRecordsFlag = false;
	showoptions = false;
	@api
	searchString = '';
	@api selectedName;
	// API properties  
	@api selectedsobject;  
	@api recordLimit = 20;  
	@api searchLabel;  
	@api searchField;
	@api searchDisabled = false;
	@api fieldType;
	@api objectjson = Object.assign({},{});

	connectedCallback() {
		this.recordLimit = 20;
	}

	@api
	loadRecords(){
		this.noRecordsFlag = 0;  
		// Wire method to function, which accepts the Search String, Dynamic SObject, Record Limit, Search Field  
		getRecordsForAutocompleteSearch({searchString: this.searchString , selectedSObject : this.selectedsobject, recordLimit : this.recordLimit, 
			searchField : this.searchField, fieldType :this.fieldType, filterMap: this.objectjson})
		.then(result => {
			this.records = this.combineRecordValues(result);
			this.error = undefined;  
			this.noRecordsFlag = this.records.length === 0 ? true : false;  
			if(!this.noRecordsFlag) this.showoptions = true;  
			else this.showoptions = false;
		})
		.catch(error => {
			this.error = error;  
			this.records = undefined;  
			this.showoptions = false;
		});
	}

	// handle event called lookupselect  
	handlelookupselect(event){
		this.selectedName = event.detail.value;
		this.showoptions = false;  
	}  

	// key change on the text field  
	handleKeyChange(event) {
		let value = event.target.value.trim();
		if(this.searchString != value){
			this.searchString = value;
			setTimeout(() => {
				this.loadRecords();
			}, 500);
		} 
	}

	// every time input changes including clicking x
	inputChanged(event) {
		if(this.searchDisabled) {
			let searchEle = this.template.querySelector('[data-id="search-input"]');
			if(searchEle) searchEle.value = this.selectedName;
			return;
		}
		this.selectedName = event.detail.value;
		if(this.selectedName == '') this.handleClear();
		if(!this.noRecordsFlag){
			const changedEvent = new CustomEvent('inputchanged');
			this.dispatchEvent(changedEvent);
		}
	}

	@api handleClear(){
		this.searchString = '';
		this.selectedName = '';
		this.records = [];
		const changedEvent = new CustomEvent('unlookupselect');
		this.dispatchEvent(changedEvent);
	}
	
	combineRecordValues(data){
		let recordMap = new Map();
		data.forEach(rec =>{
			let curRec ={};
			if(recordMap.has(rec.Id)){
				curRec.Id = recordMap.get(rec.Id).Id;
				curRec.value = recordMap.get(rec.Id).value + ', ' + rec.value;
			}else curRec = rec;
			recordMap.set(rec.Id, curRec);
		});
		return Array.from(recordMap.values());
	}
}