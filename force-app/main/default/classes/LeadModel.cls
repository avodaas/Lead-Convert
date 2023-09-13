/**
 *  LeadModel
 *    @description Base class for Lead object code, including static methods and variables
 *    @testclass  LeadModel_Test
 *    @author Avodaas
 *    @date   May 2021
 **/
public with sharing class LeadModel extends BaseModel{

    public class LeadModelException extends Exception {}

    // ========== Static Object Variables ========== //
    // ============================================= //
    public static final String STATUS_UNQUALIFIED = 'Unqualified';
    public static final String STATUS_OPEN = 'Open';
    public static final String CLASS_NAME = 'LeadModel';
    public static final List<String> AE_ROLE_NAMES = new List<String>{'Sales Account Executive', 'Partner Development Manager', 'Partner Development Rep'};
    public static final List<String> UNEXPECTED_ACCT_NAMES = new List<String>{'[not provided]'};
    public static final String HUBSPOT_USER_NAME = 'Hubspot';
    public static final String LEAD_SOURCE_PAID_SOCIAL = 'Paid Social';
    public static final String LEAD_SUB_SOURCE_LINKED_IN = 'LinkedIn';
    public static final String P1_MQL_STATUS = 'P1 MQL';
    public static final String P3_MQL_STATUS = 'P3 MQL';
    public static final List<String> P1_P3_STATUSES = new List<String>{P1_MQL_STATUS, P3_MQL_STATUS};
    public static final String DELETE_LEAD_ERROR_MSG = 'You cannot delete a lead. You can only merge duplicate leads or convert into existing contacts and accounts. Reach out to your Salesforce Administrator for additional information.';
    static Boolean runOnce = false;

    public static Id hubspotUserId{
        get{
            if(hubspotUserId == null){
                try{
                    hubspotUserId = [SELECT Id FROM User WHERE Name = :HUBSPOT_USER_NAME LIMIT 1].Id;
                } catch(Exception e){ }
            }
            return hubspotUserId;
        } private set;
    }

     // ========== Trigger Handler ========== //
    // ===================================== //

    /**
     * @description Populate records with the appropriate values on all Trigger.isBefore events
     **/
    public override void processBeforeEvents() {
        if (Trigger.isInsert) {
            capitalizeName();
        }
        if (Trigger.isUpdate) {
            capitalizeName();
        }
    }

    public override void processAfterEvents() {
        if (Trigger.isDelete) preventLeadDeletion();
        // if (Trigger.isInsert) { }
        // if (Trigger.isUpdate) { }
    }

    public void capitalizeName() {
        for(Lead curLead: (List<Lead>)triggerRecords) {
            String fname = ApxUtil.capitalizeString(curLead.FirstName);
            String lname = ApxUtil.capitalizeString(curLead.LastName);
            if (String.isNotBlank(curLead.FirstName) && !curLead.FirstName.equals(fname)) curLead.FirstName = fname;
            if (!curLead.LastName.equals(lname)) curLead.LastName = lname;
        }
    }


    @AuraEnabled(cacheable=true)
    public static List<String> getUnqualifiedReasons(){
        return Apx.getPicklistValues('Lead', 'Nurture_Unqualified_Reason__c');
    }

    @AuraEnabled
    public static Boolean massUnqualifyLeads(List<Id> leadIds, String unqualifyReason){
        List<String> legalValues = getUnqualifiedReasons();
        if(!legalValues.contains(unqualifyReason)) return false;
        List<Lead> leadsToUnqualify = new List<Lead>();
        for(Id lId:leadIds) leadsToUnqualify.add(new Lead(Id = lId, Status = STATUS_UNQUALIFIED, Nurture_Unqualified_Reason__c = unqualifyReason));
        try{
            update leadsToUnqualify;
            return true;
        } catch(Exception e){
            throw new AuraHandledException('Could not update leads updated');
        }
    }

    @AuraEnabled
    public static Boolean massDeleteLeads(List<Id> leadIds){
        try {
            List<Lead> leadsToDelete = [SELECT Id FROM Lead WHERE Id IN :leadIds];
            List<Database.DeleteResult> delList = Database.delete(leadsToDelete, false);
            String errorMessage = '';
            for (Database.DeleteResult dr : delList) {
                if (!dr.isSuccess()) {
                    for(Database.Error err : dr.getErrors()) {
                        System.debug('The following error has occurred.');
                        errorMessage += 'Error deleting lead in mass delete: code:' + err.getStatusCode() + ', Message: ' + err.getMessage() + '\r\n';
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }
            if(String.isNotEmpty(errorMessage)) ApxUtil.createErrorLog(errorMessage, CLASS_NAME);
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Don't allow leads to be deleted unless they are being merged/converted into a contact
    private void preventLeadDeletion() {
        if (FeatureManagement.checkPermission('Lead_Delete_On_Merge')) {
            for(Lead curLead: (List<Lead>)triggerRecords){
                if(curLead.MasterRecordId == null){
                    curLead.addError('Lead ' + curLead.Id + ' is not allowed to be deleted. ' + DELETE_LEAD_ERROR_MSG);
                }
            }
        }
    }
}