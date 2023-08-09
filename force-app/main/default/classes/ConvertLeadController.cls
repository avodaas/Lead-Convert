public with sharing class ConvertLeadController {

	public static final String CLASS_NAME = ConvertLeadController.class.getName();
	

	@AuraEnabled(cacheable=true)
	public static List<Lead> getLeads(Id associatedAccountId, String companyName, String website, Id currentLeadId){
		return [SELECT Id, Name, Website, Country, State, LeadSource, To_Convert__c, Email, 
			Owner.Alias, To_Opp__c, Associated_Account__c, City, Company, Status, To_Company__c, ZI_Job_Title__c
			FROM Lead
			WHERE ((Associated_Account__c <> NULL AND Associated_Account__c =: associatedAccountId) OR Company =: companyName OR (Website != null AND Website =: website))
			AND IsConverted = false AND Id != :currentLeadId  WITH SECURITY_ENFORCED];
	}
	
// returns all Opportunities that the account Id = accId	
	@AuraEnabled(cacheable=true)
	public static List<Opportunity> getAccRelatedOpps(String accId){
		if(String.isBlank(accId)) return new List<Opportunity>();
		try{
			return [SELECT Id, Name, Amount, CreatedDate, StageName FROM Opportunity WHERE AccountId =: accId AND IsClosed = false];
		} catch(Exception e){
			String message = 'Error retrieving opps for account. Account Id: ' + accId + '\r\nError: ' + e.getMessage() + '\r\nStack Trace: ' + e.getStackTraceString();
			ApxUtil.sendAdminEmail('Error in ConvertLeadController retrieving opps for account' , message);
			ApxUtil.createErrorLog(e, CLASS_NAME);
		}
		return new List<Opportunity>();
	}


  /*
    * searches (using SOSL) for all contacts with that matces the filters 
    */
	@AuraEnabled(cacheable=true)
	public static List<Contact> getSOSLRecords(String searchString, String fieldType, String selectedSObject, List<String> fieldsToReturn, Integer recordLimit){
		SoslUtil.SoslResult soslRes = SoslUtil.getSOSLRecords(searchString, fieldType, selectedSObject, fieldsToReturn, recordLimit);
		if(soslRes == null) return new List<Contact>();
		return (List<Contact>)soslRes.getResults(selectedSObject);
	}


	@AuraEnabled
	public static Id convertLeads(List<Lead> leads, Opportunity opp, Account acc, Id conId, Id currentLeadId){
		Account mainAcct = acc;
		Opportunity mainOpp = opp;
		Id navigateRecId = null;

		// Map<ConvertedContactId, LeadId>
		Map<Id, Id> contactToLeadIds = new Map<Id, Id>();
		Map<Id, String> leadRoles = new Map<Id, String>();
		String convertedStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1]?.MasterLabel;

		Savepoint sp = Database.setSavepoint();

		// Prep main lead for conversion
		Database.LeadConvert mainLc = new Database.LeadConvert();
		mainLc.setConvertedStatus(convertedStatus);
		mainLc.setLeadId(currentLeadId);
		if(conId != null) {
			Contact con = [SELECT Id, AccountId FROM Contact WHERE Id =:conId];
			if(con.AccountId != mainAcct.Id && mainAcct.Id != null){
				con.AccountId = mainAcct.Id;
				update con;
			}
			mainLc.setContactId(conId);
		}
		if (mainAcct.Id != null) mainLc.setAccountId(mainAcct.Id);
		if (mainAcct.OwnerId != null) mainLc.setOwnerId(mainAcct.OwnerId);
		if(mainOpp == null) {
			mainLc.setDoNotCreateOpportunity(true);
		}else{
			if (mainOpp.Id != null) mainLc.setOpportunityId(mainOpp.Id);
			else mainLc.setDoNotCreateOpportunity(false);
		}	

		// Convert the main lead
		try {
			Database.LeadConvertResult lcr = Database.convertLead(mainLc);
			if (lcr.isSuccess()) {
				contactToLeadIds.put(lcr.getContactId(), lcr.getLeadId());

				// If previous opp didn't exist, then Opp stage, default close date and record type were set in convertLead page. Should update opp with those values
				if (mainOpp != null && mainOpp.Id == null) {
					mainOpp.Id = lcr.getOpportunityId();
					// TODO set mainOpp.Automated_Opp_Team_Members__c = true;
					update mainOpp;
				}

				// Set SQA datetime the first time a lead is converted into a new account
				if (mainAcct.Id == null) {
					mainAcct.Id = lcr.getAccountId();
					update mainAcct;
				}
			} else {
				//Database.rollback(sp);
				throw new AuraHandledException('Main lead did not convert successfully. Error message is: \n' + ApxUtil.errorLogsLcrErrors(new List<Database.LeadConvertResult>{lcr}));
			}
		} catch (Exception e) {
			Database.rollback(sp);
			ApxUtil.sendAdminEmail('Error converting main lead', e + ' ' + e.getStackTraceString());
			throw new AuraHandledException(e.getMessage());
		}

		List<Id> leadIdsToAssociate = new List<Id>();
		// Prep the other associated leads for conversion
		List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
		for (Lead lead : leads) {
			Id leadId = lead.Id;

			// For all leads who need to be associated to the account
			if (lead.To_Company__c && !lead.To_Convert__c) {
				leadIdsToAssociate.add(leadId);
				continue;
			}

			Database.LeadConvert tempLC = new Database.LeadConvert();

			tempLC.setConvertedStatus(convertedStatus);
			tempLC.setLeadId(leadId);
			tempLC.setAccountId(mainAcct.Id);

			if (lead.To_Opp__c) {
				tempLC.setOpportunityId(mainOpp.Id);
			} else tempLC.setDoNotCreateOpportunity(true);

			leadsToConvert.add(tempLC);
		}

		if(!leadIdsToAssociate.isEmpty()) associateLeadToAccount(leadIdsToAssociate, mainAcct.Id);

		// Actually convert the other leads
		try {
			List<Database.LeadConvertResult> lcrs = Database.convertLead(leadsToConvert);
			for (Database.LeadConvertResult lcr : lcrs) {
				if (lcr.isSuccess()) {
					contactToLeadIds.put(lcr.getContactId(), lcr.getLeadId());
				} else {
					//Database.rollback(sp);
					throw new AuraHandledException('Main lead did not convert successfully. Error message is: \n' + ApxUtil.errorLogsLcrErrors(new List<Database.LeadConvertResult>{lcr}));
				}
			}

		} catch (Exception e){
			Database.rollback(sp);
			System.debug('LeadModel::convertLeads: Error Exception: ' + JSON.serializePretty(e));
			throw new AuraHandledException(e.getMessage());
		}
		if(mainOpp != null) navigateRecId = mainOpp.Id;
		else navigateRecId = mainAcct.Id;
		return navigateRecId;
	}

	//update Company Account Field on the lead object  if the to__account is selected and the field is empty 
	public static void associateLeadToAccount(List<Id> leadIds, Id accountId) {
		List<Lead> leadsToUpdate = new List<Lead>();
		for(Id leadId: leadIds) leadsToUpdate.add(new Lead(Id = leadId, Associated_Account__c = accountId));
		try {
			update leadsToUpdate;
		} catch (Exception e) {
			ApxUtil.sendAdminEmail('Error associating leads to account', e + ' ' + e.getStackTraceString());
		}
	}

	@AuraEnabled
	public static void updateRecordLead(List<Lead> leads){
		try{
			update leads;
		}catch (Exception ex){
			ApxUtil.sendAdminEmail('Error updating leads in ConvertLeadController', ApxUtil.longErrorString(ex));
			ApxUtil.createErrorLog(ex, CLASS_NAME);
		}
	}
}