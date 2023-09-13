/**
 *	ApxQL
 *		Main SOQL / SOSL query helper class for building queries that respect all FLS/CRUD rules and protect against security threats like SOQL Injection, etc
 *		@testclass	ApxQL_Test
 *		@author		Avodaas
 *		@date		May 2021
 */
public with sharing class ApxQL {

	// ========== Static Object Variables ========== //
	// ============================================= //
	public static final String CLASS_NAME = ApxQL.class.getName();

	//==== SOQL Query Helpers ====//
	//============================//


	/**
	 * FLS - Checking that the specified sobject field is accessible to the user
	 */
	public static Boolean isFieldQueryable(String sobjectName, String fieldName) {
		if (String.isBlank(sobjectName) || String.isBlank(fieldName)) return false;
		Schema.SObjectType soType = Schema.getGlobalDescribe().get(sobjectName);
		if (soType == null || !soType.getDescribe().isAccessible()) return false;
		Schema.SObjectField soField = soType.getDescribe().fields.getMap().get(fieldName);
		return isFieldQueryable(soField);
	}

	/**
	 * FLS - Checking that the specified SObjectField is accessible to the user
	 */
	public static Boolean isFieldQueryable(Schema.SObjectField field) {
		if (field == null) return false;
		return field.getDescribe().isAccessible();
	}

	
}