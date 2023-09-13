import { LightningElement, track, api, wire } from 'lwc';
import { updateRecord, getRecord, getFieldValue} from 'lightning/uiRecordApi';
import getLeads from '@salesforce/apex/ConvertLeadController.getLeads';
import { refreshApex } from '@salesforce/apex';
import convertLeads from '@salesforce/apex/ConvertLeadController.convertLeads';
import updateRecordLead from '@salesforce/apex/ConvertLeadController.updateRecordLead'; 
import { SUCCESS, WARNING, ERROR, showToastMessage } from 'c/jsUtils';
import { NavigationMixin } from 'lightning/navigation';

const OPP_PREFIX = '006';
const FIELDS_TO_RETRIEVE  = ['Lead.Company', 'Lead.Website'];
export default class LeadConvertDatatable extends NavigationMixin(LightningElement)  { 

    isOppValid;

    @api recordId;
    @api associatedAccountId;
    @api noCreateOpp;

    accId;
    companyName;
    companyWebsite;
    navigateRecId;
    error;
    isLoading = false;
    showConvert = true;
    value = 'Yes';
    options = [{label: 'Yes', value: 'Yes'}, {label: 'No', value: 'No'}];
    leads = [];
    showDataTable = false;
    draftValues = [];
    wireResult;
    isConvertAll = false;
    isOppAll = false;


    markAllLabelConvert;
    markAllLabelOpp;
    columnsList = [
        { label: 'Convert Lead?', fieldName: 'To_Convert__c', type:'boolean', editable: true},
        { label: 'Add To Opportunity', fieldName: 'To_Opp__c', type:'boolean', editable: true},
        { label: 'Add to Account', fieldName: 'To_Company__c', type:'boolean', editable: true},
        { label: 'Lead Owner', fieldName: 'owner', type: 'text'},
        { label: 'Name', fieldName: 'Name', type:'text'},
        { label: 'Email', fieldName: 'Email', type: 'text'},
        { label: 'Job Title', fieldName: 'ZI_Job_Title__c', type: 'text'}, 
        { label: 'Company', fieldName: 'Company', type: 'text'},
        { label: 'Country', fieldName: 'Country', type: 'text'},
        { label: 'Lead Source', fieldName: 'LeadSource', type: 'text'},
        { label: 'Status', fieldName: 'Status', type: 'text'}
    ];

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS_TO_RETRIEVE })
    wireRec({ error, data }) {
        if (data) {
            this.companyName = data.fields.Company.value;
            this.companyWebsite = data.fields.Website.value;
        }
        else if (error) {
            console.log('error' + JSON.stringify(error));
            this.error = error;
        }
    }

    @wire(getLeads, {associatedAccountId: '$associatedAccountId', companyName: '$companyName', website: '$companyWebsite', currentLeadId: '$recordId' })
    wiredLeads(result){
        this.wireResult = result;
        const { data, error } = result;
        if(data) {
            let selectedToConvert = 0;
            let selectedToOpps = 0;
            this.leads = data.map(row => {
                //count how many leads are selcted for conversion
                if(row.To_Convert__c) selectedToConvert++;
                if(row.To_Opp__c) selectedToOpps ++;
                let owner = row.Owner.Alias;
                return {...row, owner}
            })
            if(this.leads.length != 0){
                this.showDataTable = true;
                //if all leads are selected to convert already - unselect all
                this.isConvertAll = this.leads.length - selectedToConvert == 0 ? false : true;
                this.markAllLabelConvert = this.isConvertAll ? 'Mark All for Conversion' : 'Unmark All for Conversion';

                 //if all are selected to opps - unselect all
                 this.isOppAll = this.leads.length - selectedToOpps == 0 ? false : true;
                 this.markAllLabelOpp = this.isOppAll ? 'Mark All to Opportunity' : 'Unmark All to Opportunity';

            }
            this.error = null;
        }
        if(error) {
            console.log('error getting leads from DB' + JSON.stringify(error));
            this.error = error;
            this.leads = [];
        }
    }

    handleCancel() {
        this.showConvert = true;
    }

    handleSave(event) {
        this.isLoading = true;
        this.updateLeads(event.detail.draftValues);
    }

    updateLeads(draftValues) {
        this.isOppValid = true;
        console.log(JSON.stringify(draftValues));
        const recordInputs =  draftValues.slice().map(draft => {
            draft = this.setUpDraft(draft);
            console.log('draft:'+JSON.stringify(draft));
            return Object.assign({}, this.validateFields(draft));
        });
        
        updateRecordLead({leads: recordInputs})
        .then(() => {
            this.isLoading = false;
            if(this.isOppValid == true) showToastMessage(this, 'Success', 'All leads were updated ', SUCCESS);
            else showToastMessage(this, 'Error', 'You can only add a lead to the opportunity if you choose to convert it.', ERROR);
            this.showConvert = true;
            this.draftValues = []; // Clear all draft values
            return refreshApex(this.wireResult); // Display fresh data in the datatable
        }).catch(error => {
            this.isLoading = false;
            showToastMessage(this, 'Error', 'Error updating leads ' + error, ERROR);
            this.showConvert = true;
        });

    }

    setUpDraft(draft){
        let draftToConvertFalse = 'To_Convert__c' in draft && draft.To_Convert__c == false;
        let draftToCompanyFalse = 'To_Company__c' in draft && draft.To_Company__c == false;
        if(draft.To_Convert__c) draft.To_Company__c = true;
        else if(draftToConvertFalse) {
            draft.To_Company__c = false;
            draft.To_Opp__c = false;
        }
        if(draft.To_Company__c && !draft.To_Convert__c) draft.To_Convert__c = true; // check off to convert  //// account check off and to convert = false
        else if(draftToCompanyFalse) {
            draft.To_Convert__c = false;
            draft.To_Opp__c = false;
        }
        if(this.noCreateOpp && draft.To_Opp__c){  // Add to Opportunity && don't create opp
            draft.To_Convert__c = true;
            draft.To_Opp__c = false;
        }else if(draft.To_Opp__c){ // Add to Opportunity
            draft.To_Convert__c = true;
            draft.To_Company__c = true;
        }
        return draft;
    }

    validateFields(draft) {
        let draftToConvertTrue = 'To_Convert__c' in draft && draft.To_Convert__c == true; //a
        let draftToConvertFalse = 'To_Convert__c' in draft && draft.To_Convert__c == false;
        let draftToOppTrue = 'To_Opp__c' in draft && draft.To_Opp__c == true; //b
        let draftToOppFalse = 'To_Opp__c' in draft && draft.To_Opp__c == false;
        let draftToCompanyFalse = 'To_Company__c' in draft && draft.To_Company__c == false;
        
        //if just has associated account 
        if((draftToConvertTrue && draftToCompanyFalse) || (draftToConvertFalse && draftToOppFalse)) this.isOppValid = true;
        else {
            //if a draft is false
            if(draftToConvertFalse) {
                //if b draft is true -> make a draft true
                if(draftToOppTrue) {
                    draft.To_Convert__c = true;
                    this.isOppValid = false;
                }
                //b not in draft
                else {
                    this.leads.forEach(ele => {
                        if(ele.Id == draft.Id) {
                            //if b old is true
                            if(ele.To_Opp__c == true) {
                                draft.To_Convert__c = true;
                                this.isOppValid = false;
                            }
                        }
                    })
                }
            }
            //if b draft is true
            if(draftToOppTrue && draftToConvertFalse) {
                //if a draft is false -> make b draft false
                if(draftToConvertFalse) {
                    draft.To_Opp__c = false;
                    this.isOppValid = false;
                }
                //a not in draft
                else {
                    this.leads.forEach(ele => {
                        if(ele.Id == draft.Id) {
                            //if a old is true
                            if(ele.To_Convert__c == false) {
                                draft.To_Opp__c = false;
                                this.isOppValid = false;
                            }
                        }
                    })
                }
            }
        }
        return draft;
    }

    handleKeyUp(event){
        this.showConvert = false;
    }

    fireConvertEvent(event){
        this.dispatchEvent(new CustomEvent('convert', {
            detail: event,
            bubbles: true,
            composed: true
        }));
    }

    @api
    convertToLead(account, opp, conId){
        this.isLoading = true;
        let isvalid = true;
        let rows = [];
        this.leads.forEach(ele => {
            if(ele.To_Convert__c){
                if(!opp && ele.To_Opp__c) {
                    showToastMessage(this, 'Error', 'Please select an existing opportunity or deselect \'Add To Opportunity\' in the table below.', ERROR);
                    this.isLoading = false;
                    isvalid = false;
                }
                ele.Owner = null;
                rows.push(ele);
            }
        })
        if(!isvalid) return;
        convertLeads({leads: rows , opp: opp, acc: account, conId: conId, currentLeadId: this.recordId})
        .then(result=>{
            this.navigateRecId = result;
            this.isLoading = false;
            showToastMessage(this, 'Success', 'Lead Successfully Converted', SUCCESS);
            this.navigateToViewOppOrAccPage();
            refreshApex(this.wireResult);
        }).catch(error => {
            this.isLoading = false;
            showToastMessage(this, 'Error', 'Error ' + JSON.stringify(error.body.message) + error, ERROR);
            console.log('error ' + JSON.stringify(error));
        })
    }


    navigateToViewOppOrAccPage(){
        const objectApiName = this.navigateRecId.startsWith(OPP_PREFIX) ? 'Opportunity' : 'Account';
        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.navigateRecId,
                    objectApiName: objectApiName,
                    actionName: 'view'
                },
            });

        } catch (error) {
            console.log('error ' +JSON.stringify(error));
        }
    }

    selectAllLeadsToConvert(){
        this.selectAllLeads(false);
    }

    selectAllLeads(withOpps) {
        this.showConvert = false;
        this.isLoading = true;
        let draft = [];
        this.leads.forEach(ele => {
            //only if wasn't like that already - update
            if(ele.To_Convert__c != this.isConvertAll || (withOpps && ele.To_Opp__c != this.isOppAll)) {
                let dr = {};
                if(!withOpps) dr.To_Convert__c = this.isConvertAll;
                 // add/unmarck opp selcted? select/unselect all opps ?  ( the Mark/unmark convert lead is clicked ? unmark convert all leads ? to_opp = false : stays the same from db) 
                dr.To_Opp__c =  withOpps ? this.isOppAll : (!this.isConvertAll ? this.isConvertAll : ele.To_Opp__c);
                dr.Id = ele.Id;
                draft.push(dr);
            }
        });
        this.draftValues = draft;
        this.isLoading = false;
    }

    selectAllLeadsToOpp(){
        this.selectAllLeads(true);
    }
}