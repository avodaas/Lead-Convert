/**
 *	ApxQL_Test
 *		@classesTested	ApxQL
 *		@author			Avodaas
 *		@date			May 2021
 */
@isTest
private with sharing class ApxQL_Test {

	@isTest static void ApxQL_HelperMethods_CodeCoverage() {
		System.assert(ApxQL.isFieldQueryable('Organization', 'Id'));
		System.assert(!ApxQL.isFieldQueryable('MyBogusCustomObject', 'Id'));
		System.assert(!ApxQL.isFieldQueryable('Organization', 'MyBogusCustomField'));
	}

}