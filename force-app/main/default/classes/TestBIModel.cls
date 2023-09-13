/**
 *	
 *	  @description Abstract class for initializing Airvet-specific data for unit tests.
 *	  @example  TestModel.initData();
 *				TestModel.city1.ParentId = TestModel.country1.Id;
 *				update TestModel.city1;
 *	  @author Avodaas
 *	  @date	Aug 2020
 */
public abstract with sharing class TestBIModel {
  
    public static Lead myLead;

    public static void initData(){  
        myLead = (Lead)SmartFactory.createSObject('Lead', false);
        myLead.lastName = 'Test';
        myLead.Email = 'lead@email.com';
        myLead.Company = 'A nice company';
        myLead.OwnerId = UserInfo.getUserId();
    }
}