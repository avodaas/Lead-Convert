/**
 *  ApxUtil_Test
 *    Unit tests for ApxUtil class
 *  
 **/
@isTest
public class ApxUtil_Test {

    @isTest static void ApxUtil_helperMethods_Test() {
        UnsupportedObjectTypeException uote = new UnsupportedObjectTypeException();
        ApxUtil.longErrorString(uote);
        String fName = 'ApxUtil_Test';
        String errorString = 'Bad Email Value';
        ApxUtil.createErrorLog(errorString, fName);
        Account acc1 = new Account(Name = 'Account1');
        insert acc1;
        Contact con1 = new Contact(LastName ='conLast', AccountId = acc1.Id);
        insert con1;
        try{
            con1.Email = 'bad Value';
            update con1;
        }catch(Exception ex) {
            ApxUtil.createErrorLog(ex, 'ApxUtil_Test');
        }
        ApxUtil.createErrorLog(uote, 'ApxUtil_Test');
        System.assertEquals(errorString, [SELECT Error_Message__c FROM Avodaas_Logs__c WHERE File_Name__c = :fName  LIMIT 1].Error_Message__c);
        //no users :), no roles set up, so shouldn't return any user roles.
        //== ApxUtil.sendEmail() Unit tests for ==//
        ApxUtil.sendAdminEmail('Email Subject', 'Body of the test email');
        System.assertEquals(' Phone like \'%5555555555%\' ',ApxUtil.toWhereClause('Contact', 'Phone', '5555555555'));
        System.assertEquals(' LastName like \'TestLastName%\' ', ApxUtil.toWhereClause('Contact', 'LastName', 'TestLastName'));
        System.assertEquals(' (LastName like \'TestLastName%\' OR LastName like \'TestFirstName%\' ) ',  ApxUtil.toWhereClause('Contact', 'LastName', 'TestLastName,TestFirstName'));
        System.assertEquals(' Type = \'Mechanical\' ', ApxUtil.toWhereClause('Case', 'Type', 'Mechanical'));
        System.assertEquals('  (Reason = \'Installation\' OR Reason = \'Performance\')', ApxUtil.toWhereClause('Case', 'Reason', 'Installation;Performance|'));
        System.assertEquals(' Id = \'000000000000000AAA\' ',ApxUtil.toWhereClause('Case', 'Id', '000000000000000AAA'));
        System.assertEquals(' Id in (000000000000000AAA,000000000000000AAB) ',ApxUtil.toWhereClause('Case', 'Id', '(000000000000000AAA,000000000000000AAB)'));
        System.assertEquals(' AccountId = \'000000000000000AAA\' ', ApxUtil.toWhereClause('Contact', 'AccountId', '000000000000000AAA'));
        System.assertEquals(' NumberOfEmployees >= 6  AND NumberOfEmployees <=  5 ' ,ApxUtil.toWhereClause('Account', 'NumberOfEmployees', '6 - 5'));
        System.assertEquals(' NumberOfEmployees <=  5 ' ,ApxUtil.toWhereClause('Account', 'NumberOfEmployees', '< 5'));
        System.assertEquals(' NumberOfEmployees >=  5 ' ,ApxUtil.toWhereClause('Account', 'NumberOfEmployees', '> 5'));
        System.assertEquals(' NumberOfEmployees = 5 ' ,ApxUtil.toWhereClause('Account', 'NumberOfEmployees', '5'));
        System.assertEquals(' IsConverted = false' ,ApxUtil.toWhereClause('Lead', 'IsConverted', 'No'));
        System.assertEquals(' Description like \'%some text%\' ' ,ApxUtil.toWhereClause('Case', 'Description', 'some text'));
        // System.assertEquals(' App_Currencies__c includes (\'AUD (A$)\')' ,ApxUtil.toWhereClause('Opportunity', 'App_Currencies__c', 'AUD (A$)')); 
        System.assertEquals('Account', ApxUtil.getObjectNameById(acc1.Id));
        System.assertEquals(true, ApxUtil.isSObjectAndfieldExists('Contact', 'Name'));
        System.assertEquals(false, ApxUtil.isSObjectAndfieldExists('Bad Obj', ''));
        System.assertEquals(false, ApxUtil.isSObjectAndfieldExists('Account', 'Bad Field'));
        
        ApxUtil.getSObjectFieldsForObjectByType('Contact', 'email');
        try{
           ApxUtil.getSObjectFieldsForObjectByType('Bad Obj', 'Name');
        } catch (Exception e) { /* Testing catch exception */ }
        System.assertEquals(true,ApxUtil.trackedFieldsByObject('Opportunity').contains('StageName')); // Opportunity.StageName tracked by default
    }

    @isTest static void ApxUtil_LeadConvert() {
        TestBIModel.initData();
        String convertedStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1]?.MasterLabel;
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(TestBIModel.myLead.Id); //contactId instead of leadId for code coverage
        lc.setConvertedStatus(convertedStatus);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        ApxUtil.errorLogsLcrErrors(new List<Database.LeadConvertResult>{lcr});
    }
}