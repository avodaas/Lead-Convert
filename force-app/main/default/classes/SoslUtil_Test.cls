/**
 *	
 *	  @description SoslUtil_Test class unti test for SoslUtil. 
 *	  @author Avodaas
 *	  @date	july 2022
 */

@IsTest
public with sharing class SoslUtil_Test {
    @isTest
    static void SoslUtil_coverage_Test() {
        Contact con = new Contact(LastName = 'soslTest', Email='soslTest@gmail.com');
        insert con;
        Id [] fixedSearchResults = new Id[1];
        fixedSearchResults[0] = con.Id;
        SoslUtil.soslResult res, res1;
        Test.setFixedSearchResults(fixedSearchResults);
        test.startTest();
        res = SoslUtil.getSOSLRecords('Test', 'Name', 'Contact', new List<String> {'Id','Name', 'Account.Name'}, 10);
        res1 = SoslUtil.getSOSLRecords('Test', 'Name', 'Contact', new List<String> {'Id', 'badfield'}, 10);
        test.stopTest();
        system.assertEquals(false, res.getResults('Contact').isEmpty());
        system.assertEquals(null, res1); 
    }
}