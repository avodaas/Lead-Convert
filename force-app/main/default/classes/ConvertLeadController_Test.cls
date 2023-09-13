@isTest
public with sharing class ConvertLeadController_Test {
    @isTest
    static void convertleadController_coverage_Test() {
        Account ac = new Account(Name ='Test1');
        Account newAcc = new Account(Name ='newAcc');
        insert ac;
        Opportunity op = new Opportunity (AccountId = ac.Id, Name = 'testName', CloseDate = Date.today(), stageName = 'Qualified');
        Opportunity newOpp = new Opportunity (AccountId = ac.Id, Name = 'newOpp', CloseDate = Date.today(), stageName = 'Qualified');
        insert op;

        Lead newLead = new Lead(lastName = 'Test', Email = 'leatest@email.com', Company = 'A nice company');
        insert newLead;
        
        TestBIModel.initData();
        TestBIModel.myLead.To_Company__c = false;
        TestBIModel.myLead.To_Convert__c = false;
        update TestBIModel.myLead;
        Id [] fixedSearchResults = new Id[1];
        fixedSearchResults[0] = TestBIModel.vet2.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
        convertleadController.getAccRelatedOpps(ac.Id);
        try {convertleadController.getAccRelatedOpps('badval');}catch (Exception e) {}
        system.assertEquals(TestBIModel.badLandingPageLead.Id, ConvertLeadController.getLeads(TestBIModel.hospital1.Id, TestBIModel.campaignLead.Id)[0]?.Id);
        system.assertEquals(true, ConvertLeadController.getLeads(TestBIModel.clinic1.Id, TestBIModel.myLead.Id).isEmpty());
        // good convert 
        try {
            convertleadController.convertLeads(new List<Lead>{TestBIModel.myLead, TestBIModel.campaignLead}, op, ac, TestBIModel.vet1.Id, TestBIModel.leadWithParams.Id);
        } catch (Exception e) {
            System.debug('error ' + e);
        }
        // bad mainLead Id
        try {
            convertleadController.convertLeads(new List<Lead>(), op, ac, null, op.Id);
        } catch (Exception e) {
            System.debug('error ' + e);
        }
        // associate with the main leads account and opp 
        try {
            op.Id = null;
            ac.Id = null;
            convertleadController.convertLeads(new List<Lead>{TestBIModel.badLandingPageLead}, newOpp, newAcc, null, TestBIModel.myLead.Id);
        } catch (Exception e) {
            System.debug('error ' + e);
        }
        convertleadController.updateRecordLead(new List<Lead>{TestBIModel.campaignLead});

        convertleadController.associateLeadToAccount(new List<Id>{newLead.Id},TestBIModel.hospital1.Id );
        try {
            convertleadController.associateLeadToAccount(new List<Id>{TestBIModel.hospital1.Id},TestBIModel.hospital1.Id );
        }catch (Exception ex) { System.debug('error ' + ex);}
        system.assertEquals(false, convertleadController.getSOSLRecords('Erin', 'Name', 'Contact', new List<String>{'Id','Name','Email'} ,10).isEmpty());
        Test.stoptest();

        system.assertEquals(true, [SELECT Id, IsConverted FROM Lead WHERE Id =: TestBIModel.campaignLead.Id LIMIT 1]?.IsConverted);
        //try to get an error 

        convertleadController.getAccRelatedOpps(ac.Id);
       
    }
}