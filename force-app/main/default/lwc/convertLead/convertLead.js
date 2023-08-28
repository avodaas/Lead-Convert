import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue} from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { SUCCESS, ERROR, validateSections, formValid, showToastMessage } from 'c/jsUtils';

import getAccRelatedOpps from '@salesforce/apex/ConvertLeadController.getAccRelatedOpps';
import getSOSLRecords from '@salesforce/apex/ConvertLeadController.getSOSLRecords'; 


/*Lead Fields*/
import LEAD_NAME from '@salesforce/schema/Lead.Name';
import LEAD_ACCOUNT_FIELD from '@salesforce/schema/Lead.Associated_Account__c';
import LEAD_EMAIL from '@salesforce/schema/Lead.Email';

/*Account Fields*/
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ACCOUNTID_FIELD from '@salesforce/schema/Account.Id';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';

/*Opportunity Fields*/
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import OPPORTUNITYID_FIELD from '@salesforce/schema/Opportunity.Id';
import OPPORTUNITY_NAME_FIELD from '@salesforce/schema/Opportunity.Name';
import OPPORTUNITY_CREATEDDATE_FIELD from '@salesforce/schema/Opportunity.CreatedDate';
import OPPORTUNITY_STAGE_FIELD from '@salesforce/schema/Opportunity.StageName'; 
import OPPORTUNITY_AMOUNT_FIELD from '@salesforce/schema/Opportunity.Amount'; 

/*Contact fields*/
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import CONTACT_ID from '@salesforce/schema/Contact.Id';
import CONTACT_NAME from '@salesforce/schema/Contact.Name';
import CONTACT_ACCOUNTNAME from '@salesforce/schema/Contact.Account.Name';
import CONTACT_ACCOUNTID from '@salesforce/schema/Contact.AccountId';
import CONTACT_ACCOUNTTYPE from '@salesforce/schema/Contact.Account.Type';
import CONTACT_PHONE from '@salesforce/schema/Contact.Phone';
import CONTACT_EMAIL from '@salesforce/schema/Contact.Email';
import CONTACT_TITLE from '@salesforce/schema/Contact.Title';

const fields = [LEAD_NAME, LEAD_ACCOUNT_FIELD, LEAD_EMAIL];
const accountFields = [ACCOUNT_NAME_FIELD];
const contactApiFields = [CONTACT_ID, CONTACT_NAME, CONTACT_ACCOUNTID, CONTACT_ACCOUNTTYPE, CONTACT_ACCOUNTNAME, CONTACT_PHONE, CONTACT_EMAIL, CONTACT_TITLE]; //CONTACT_ACCOUNTNAME
const CONTACT_FIELDS = [CONTACT_ID.fieldApiName, CONTACT_NAME.fieldApiName, CONTACT_TITLE.fieldApiName, CONTACT_ACCOUNTTYPE.fieldApiName, CONTACT_ACCOUNTNAME.fieldApiName, CONTACT_PHONE.fieldApiName, CONTACT_EMAIL.fieldApiName, CONTACT_ACCOUNTID.fieldApiName];
const TEXT_SELECTED_CONTACTS = ' Contacts Match by email';
const TEXT_MATCHING_CONTACTS = ' potential matches';

const CONTACT_FIELDS_TO_DISPLAY = [CONTACT_NAME.fieldApiName, CONTACT_ACCOUNTID.fieldApiName, CONTACT_PHONE.fieldApiName, CONTACT_EMAIL.fieldApiName, CONTACT_TITLE.fieldApiName];
const OPP_FIELDS_TO_DISPLAY = [OPPORTUNITY_NAME_FIELD.fieldApiName, OPPORTUNITY_CREATEDDATE_FIELD.fieldApiName, OPPORTUNITY_STAGE_FIELD.fieldApiName, OPPORTUNITY_AMOUNT_FIELD.fieldApiName];

const RECORD_LIMIT = 10;
export default class ConvertLead extends LightningElement {
	selectedAccountId; //selected Account Id
	selectedOppId = null; //selected opportunity Id
	selectedAccount = false; //selected account record- show disabled inputs with values for the selected account
	accountSelectedName = false; // if the lead has a Associated_Account__c the autoComplete populates the accountName
	accSearchDisabled = false; // Lead.Associated_Account__c not empty
	disableOppRb = true;
	accToggle = false; //when accToggle = false => the create account section pops and when accToggle = true =>  select account section pops
	oppToggle = false; //when oppToggle.false = the create opporunity section pops and when oppToggle.true  = the select opportunity section pops
	conToggle = false; //when conToggle.false = the create contact section pops and when conToggle.true  = the select contact section pops
	checkedOp1 = true; //check off the first radio button opportunity
	checkedOp2 = false; //check off the second radio button opportunity
	checkedAC1 = true;//check off the first radio button on account - create
	checkedAC2 = false;//check off the second radio button on account -existing
	checkedCon1  = true; //check off the first radio button on contact - create
	checkedCon2 = false;//check off the second radio button on contact -existing
	selectedConId; // selected contactId
	showContacts = false; // show contacts tiles
	addContactId = false; // selected contactId from autocomplete using this for wire with $ 
	selectedContact = false; // selected contact from autocomplete for getting all contact fields 
	disableAccount = false; // disable account checkboxes
	leEmail; // leadEmail to sosl all matching contacts by it
	numEmailMatch = TEXT_SELECTED_CONTACTS; // text for matching or potential contacts
	matchingContacts = []; // a list of all matching contact by email and by selected contacts form the drop down
	matchingOpps = []; // a list of all matching opps by accountId
	selectedContactsIds = [];// a list of all selected contact ids form the drop down
	selectedContactName = false;
	noCreatingOpp = false; // check box 
	contactMapFields; // key = api name value => label 
	oppMapFields;// key = api name value => label
	hideOppOption2 = false;
	oppInputReq = true;
	lead = {};
	@api recordId;

	//  Map key => field api name , value - label of contact fields to display
	@wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    contactInfo({ data, error }) {
        if (data){
			let fieldsMap = {};
			CONTACT_FIELDS_TO_DISPLAY.forEach(ele => {
				let field = data.fields[ele];
				if(field.hasOwnProperty('dataType') && field.dataType == 'Reference'){ 
					let fieldName = field.referenceToInfos[0].apiName; 
					let fieldLabel = fieldName + ' ' + field.referenceToInfos[0].nameFields[0]; //example : Account Name
					fieldsMap[fieldName] = fieldLabel;
				}else fieldsMap[field.apiName] = field.label;
			});
			this.contactMapFields = fieldsMap;
		}else if (error) console.log('error getting contact object Info:' + JSON.stringify(error));
	}

	//  Map key => field api name , value - label of opp fields to display
	@wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    oppInfo({ data, error }) {
        if (data){
			let fieldsMap = {};
			OPP_FIELDS_TO_DISPLAY.forEach(ele => {
				console.log(ele);
				let field = data.fields[ele];
				fieldsMap[field.apiName] = field.label;
			});
			this.oppMapFields = fieldsMap;
		}else if (error) console.log('error getting opportunity object Info:' + JSON.stringify(error));
	}

	// get matching contacts by email
	@wire(getSOSLRecords, {searchString: '$leEmail', fieldType: 'Email', selectedSObject: CONTACT_OBJECT, fieldsToReturn: CONTACT_FIELDS, recordLimit: RECORD_LIMIT})
	getcontacts({data, error}){
		if (data){
			this.matchingContacts = data;
		} 
		else if (error) console.log('error getting contact list:' + JSON.stringify(error));
	}

	// get contact detail from the contact from the drop down 
	@wire(getRecord,{ recordId: '$addContactId', fields:  contactApiFields})
	getSelectedContact({data, error}){
		if (data){
			this.selectedContact = data;
			const con = {Id: this.addContactId, Name: this.contactName, AccountType: this.contactAccountType, AccountName: this.contactAccountName ,Account: {Name: this.contactAccountName , Type: this.contactAccountType, Id: this.contactAccountId}, AccountId: this.contactAccountId,  Email: this.contactEmail, Phone: this.contactPhone, Title: this.contactTitle};
			this.selectedContactsIds.push(this.addContactId); // for clearing out when checking new contact 
			this.matchingContacts = [...this.matchingContacts, con];
			this.populateAccount(); // populate matching account on the drop down
		}else if (error) console.log('error getting selected contact information:' + JSON.stringify(error));
	}

	// get current lead info 
	@wire(getRecord, { recordId: '$recordId', fields: fields })
	getCurLead({data, error}){
		if (data){
			if(Object.keys(this.lead).length === 0){ // first Time loading the lead
				this.lead = data;
				this.leEmail = this.leadEmail; // for the track - calling matching contacts with $ getcontacts wire 
				this.populateRelatedObjectSeetings();
			} else this.lead = data;
		}else if (error) console.log('error getting current lead:' + JSON.stringify(error));
	}

	// get selcted account information
	@wire(getRecord, { recordId: '$selectedAccountId', fields:  accountFields})
	getCurAcc({data, error}){
		if (data){
			this.selectedAccount = data;
			this.accountSelectedName = this.assoicatedAccountName;
		} else if (error) console.log('error getting current account:' + JSON.stringify(error));
		
	}

	get contactAccountName(){
		return  getFieldValue(this.selectedContact, CONTACT_ACCOUNTNAME);
	}

	get contactAccountType(){
		return  getFieldValue(this.selectedContact, CONTACT_ACCOUNTTYPE);
	}

	get contactName(){
		return getFieldValue(this.selectedContact, CONTACT_NAME);
	}

	get contactEmail(){
		return getFieldValue(this.selectedContact, CONTACT_EMAIL);
	}

	get contactPhone(){
		return getFieldValue(this.selectedContact, CONTACT_PHONE);
	}

	get contactTitle(){
		return getFieldValue(this.selectedContact, CONTACT_TITLE);
	}

	get contactAccountId(){
		return getFieldValue(this.selectedContact, CONTACT_ACCOUNTID); 
	}

	get leadName(){
		return getFieldValue(this.lead, LEAD_NAME);
	}

	get leadEmail(){
		return getFieldValue(this.lead, LEAD_EMAIL);
	}

	get contactsLength(){
		return this.matchingContacts.length + ' ' + this.numEmailMatch;
	}

	get oppsLength(){
		return this.matchingOpps.length + ' ' + 'Opportunities Match By Account';
	}

	get assoicatedAccountName(){
		return getFieldValue(this.selectedAccount, ACCOUNT_NAME_FIELD); 
	}

	get associatedAccountId(){ // associated AccountId from lead object
		let accId = getFieldValue(this.lead, LEAD_ACCOUNT_FIELD);
		return accId == null || Object.keys(accId).length === 0 ? null : accId;
	}

	//new account 
	changeAcountName(event){
		this.accountSelectedName = event.detail.value;
	}

	//new opp
	changeOppName(event){
		this.opportunitySelectedName = event.detail.value;
	}

	// if the lead.assosiate_account is filled populate the account
	populateRelatedObjectSeetings(){
		if(this.associatedAccountId){
			this.selectedAccountId = this.associatedAccountId; //selectedAccountId on the convert lead
			this.toggleExistingAccount();
			this.getRelatedOpps(); // get realted opps to the account
		}
	}

	// when selecting an account from the drop down
	handleAccountChange(event){
		this.selectedAccountId = event.detail.Id;
		if(this.selectedAccountId){
			this.getRelatedOpps();
		}
	}

	//when selecting a contact from drop down
	handleConChange(event){
		this.selectedConId = event.detail.Id;
		if(this.numEmailMatch != TEXT_MATCHING_CONTACTS) this.numEmailMatch = TEXT_MATCHING_CONTACTS; // change matching title text
		if(!this.contactExist()) this.addContactId = this.selectedConId; // add to matching contacts - calls a wire getSelectedContact
		else {
			this.template.querySelector('c-tiles[data-id="tileConId"]').checkRecord(this.selectedConId); // check the contact tile
			this.template.querySelector('c-tiles[data-id="tileConId"]').addBorder(this.selectedConId);
			this.populateAccount(); //populate account
		}	
	}

	// checks if the selected contains in the matchingContacts
	contactExist(){
		for( let i = 0 ; i< this.matchingContacts.length ; i++){
			if(this.matchingContacts[i].Id == this.selectedConId)  return true
		} return false;
	}

	togglesForNewOpp(){
		//if(this.noCreatingOpp) return;
		this.oppToggle = false; // showing new opp 
		if(!this.noCreatingOpp) {
			this.oppInputReq = true;
			this.checkedOp2 = false; // select existing opp = false;
			this.checkedOp1 = true; // new opp = true;
		}
	}
	

	// unselect an account clear all the account fields and set checkboxes
	handleClearAccount(){
		this.togglesForNewOpp();
		this.clearExistingAccount();
		this.clearOutOppSearch();
	}

	// get realted opp for selected account
	getRelatedOpps(){
		getAccRelatedOpps({ accId : this.selectedAccountId})
		.then(opps => {
			let noOpps = opps.length === 0 ? true : false;
			this.hideOppOption2 = noOpps ? true : false; // "select existing" would disappear if there's no opps
			if(this.disableOppRb) this.disableOppRb = false; //can click on create new opp.
			opps = opps.map(opp => {
				let temp = Object.assign({}, opp);
				let curDate = new Date(opp.CreatedDate);
				temp.CreatedDate = curDate.toDateString();
				return temp;
			});
			this.togglesForNewOpp();
			this.matchingOpps = opps;
		}).catch((errorGettingRelatedOpps) => {console.log(' ^^^ error getAccountRecord -> getAccRelatedOpps::' + JSON.stringify(errorGettingRelatedOpps));});
	}

	// unselect a contact from drop down
	clearExistingCon(){
		if(this.selectedContactsIds.includes(this.selectedConId)){ // remove contact from the contact list only if it didn't match by email
			this.matchingContacts = this.matchingContacts.filter(con => { 
				return con.Id != this.selectedConId;
			});
			this.matchingContacts = [... this.matchingContacts];
		} else{ // matching contacts - clear out all checkboxes
			this.template.querySelector('c-tiles[data-id="tileConId"]').clearoutCheckedRecords();
		}
		this.selectedConId = null;
		this.selectedContactName = null;
		this.addContactId = null;
	}

	//clear selected account values from radio buttons
	clearExistingAccount(){
		this.selectedAccountId = false;
		this.selectedAccount = false;
		this.accSearchDisabled = false;
		this.accountSelectedName = false;
	}

	changetoggle(event){
		try{
			let objtarget = event.detail;
			if(objtarget.typeobj === 'acc') {
				this.clearExistingAccount();
				if(objtarget.option == 'Create New'){
					this.accToggle = false;
					this.checkedAC1 = true;
					this.checkedAC2 = false;
					this.clearOutOppSearch();
				} else { // select existing
					this.toggleExistingAccount();
					this.togglesForNewOpp();
					this.populateAssociatedAccount();
				}
			}else {
				if(objtarget.typeobj === 'opp') {// an opportunity toggle 
					if(this.noCreatingOpp) this.noCreatingOpp = false;
					if(objtarget.option == 'Create New') {
						this.selectedOppId = false;
						this.opportunitySelectedName = false;
						this.togglesForNewOpp();
					} else {
						this.oppToggle = true; // shows the autoComplete
						this.checkedOp1 = false;
						this.checkedOp2 = true;
						if(this.matchingOpps.length == 1) this.selectedOppId = this.matchingOpps[0].Id; // only if on init there's one contact match in db
					}
				} else{
					//contact 
					if(objtarget.option == 'Create New') {
						this.conToggle = false;
						this.checkedCon1 = true;
						this.checkedCon2 = false;
						this.selectedConId = null; // new contact
						this.selectedContactName = null;
						this.removeSelectedContacts();
						this.clearExistingAccount();
						this.clearOutOppSearch();
						if(this.disableAccount) this.disableAccount = false;
						if(this.accToggle == true) this.populateAssociatedAccount();
					} else{
						this.conToggle = true;//select con
						this.checkedCon1 = false;
						this.checkedCon2 = true;
						this.toggleExistingAccount();
						if(this.matchingContacts.length == 1) { // only if on init there's one contact match in db
							this.selectedConId = this.matchingContacts[0].Id;
							this.populateAccount();
						}
					}
				}
			}
		}catch(error){console.error(error);}
	}

	//populate associated account from the current lead
	populateAssociatedAccount(){
		if(!this.associatedAccountId) return;
		this.selectedAccountId = this.associatedAccountId;
		this.accountSelectedName = this.assoicatedAccountName;
		this.getRelatedOpps();
	}

	// clear out opp search and check new opp radio button
	clearOutOppSearch(){
		this.matchingOpps = [];
		this.togglesForNewOpp();
		this.disableOppRb = true;
		this.opportunitySelectedName = null;
		this.selectedOppId = null;	//clear out existing opp
	}

	// remove all selected contacts from the drop down on the tiles
	removeSelectedContacts(){
		this.matchingContacts = this.matchingContacts.filter(con => { 
			return !this.selectedContactsIds.includes(con.Id);
		});
		this.matchingContacts = [...this.matchingContacts]; // fires the tiles
		this.selectedContactsIds = [];
		this.addContactId = null;
	}

	get showOppDetails(){
		return this.noCreatingOpp ?  ' display: none; ' : 'display: block;' ;
	}

	handleNoOppsCreate(event){
		this.noCreatingOpp = event.target.checked;
		if(this.noCreatingOpp){
			this.checkedOp1 = false;
			this.checkedOp2 = false;
			this.selectedOppId = null;
			this.oppInputReq = false;
			setTimeout(() => {formValid(this,'lightning-input');});
		}else{ 
			this.togglesForNewOpp();
			this.oppInputReq = true;
			if(this.matchingOpps.length > 0) this.disableOppRb = false; // has matching opps 
		}
	}
	toggleExistingAccount(){
		this.accToggle = true;
		this.checkedAC1 = false;
		this.checkedAC2 = true;
	}

	// when contact is selected
	populateAccount(){
		this.disableAccount = true; // you can't check account check boxes
		let oldSelectedAccId = this.selectedAccountId;
		this.matchingContacts.forEach(con => {
			if(con.Id == this.selectedConId) {
				if(con.AccountId){
					this.selectedAccountId = con.AccountId;
					this.accountSelectedName = con.Account.Name;
					if(!this.accToggle) this.toggleExistingAccount();
				}
			}
		});
		this.accSearchDisabled = this.selectedAccountId ? true : false; // disable autocomplete serach on account only if it found a matching account
		if(oldSelectedAccId != this.selectedAccountId){
			this.clearOutOppSearch(); // clearout existing opps
			this.getRelatedOpps(); // check existing opps only if the selected account has opps
		}
	}

	handleConvert(event){
		let cmpValid = formValid(this,'lightning-input');
		if(!cmpValid) showToastMessage(this, 'Error', 'Please complete required fields.', ERROR);
		else this.updateCreateOppandAcc();
	}

	updateCreateOppandAcc(){
		let accInput = this.getAccount();
		let oppInput = this.getOpportunity();
		if(!validateSections(this.conToggle, this.selectedConId, 'Please Select/Check existing Contact.')) return;
		if(!validateSections(this.accToggle, this.selectedAccountId, 'Please Select existing Account.')) return;
		if(!this.noCreatingOpp && !validateSections(this.oppToggle, this.selectedOppId, 'Please Select existing Opportunity.')) return;
		let conId = this.selectedConId;
		this.template.querySelector('c-lead-Convert-Datatable').convertToLead(accInput, oppInput, conId);
	}

	setupNewAccount(fields){
		fields[ACCOUNT_NAME_FIELD.fieldApiName] = this.accountSelectedName;
		return fields;
	}

	setupNewOpportunity(fields){
		fields[OPPORTUNITY_NAME_FIELD.fieldApiName] = this.opportunitySelectedName;
		return fields;
	}

	/* sets the account fields in an object */
	getAccount(){
		let fields = {'sobjectType': ACCOUNT_OBJECT.objectApiName};
		if(this.selectedAccountId) fields[ACCOUNTID_FIELD.fieldApiName] = this.selectedAccountId;
		else fields = this.setupNewAccount(fields);
		return fields;
	}

	/* sets the Opportunity fields in an object */
	getOpportunity(){
		if(this.noCreatingOpp) return null; // don't create an opportuninty upon conversion
		let fields = {'sobjectType': OPPORTUNITY_OBJECT.objectApiName};
		if(this.selectedOppId) fields[OPPORTUNITYID_FIELD.fieldApiName] = this.selectedOppId;
		else this.setupNewOpportunity(fields);
		return fields;
	}

	//selected opp from tiles 
	handleSelectedOpp(event){
		this.selectedOppId = event.detail;;
	}

	//selected contact from tiles 
	handleSelectedContact(event){
		this.selectedConId = event.detail;
		// display the selected contact's name in the search bar
		let selectedContact = this.getSelectedContactById();
		if(selectedContact) this.selectedContactName = selectedContact.Name;// display on the drop down
		this.populateAccount(); // popuate realted account on the page
	}

	getSelectedContactById(){
		for (let i = 0; i < this.matchingContacts.length; i++){
			if(this.matchingContacts[i].Id == this.selectedConId) 
				return this.matchingContacts[i];
		}
		return null;
	}
}