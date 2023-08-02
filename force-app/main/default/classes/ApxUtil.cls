/**
 * Extension for Apx class, with methods that were developed after Apx was packaged for this org
 */
public class ApxUtil{

    /*
    * @description the function gets a string and inserts an error log record
    * @params String Exception, fileName
    * @returns void
    */
    public static final String CLASS_NAME = 'ApxUtil';
    public static final String ADMIN_SENDER_DISPLAYNAME = UserInfo.getOrganizationName();
    public static final String ADMIN_REPLYTO_EMAIL = 'trullion-admin@avodaas.com';
    public static List<String> ADMIN_EMAILS = new List<String>{'trullion-admin@vodaas.com'};  //UserInfo.getUserEmail()

    /**
	*  @description Accepts an object and returns all the custom fields
	*/
	public static List<String> getCustomFieldsForSObject(String ObjName){
		List<String> customFields = new List<String>();
		Map <String, Schema.SObjectField> fieldMap = ApxUtil.getSObjectFields(ObjName);
		for(Schema.SObjectField sfield : fieldMap.Values()){
			if(sfield.getDescribe().getName().endsWith('__c'))customFields.add(sfield.getDescribe().getName());
		}
		return customFields;
	}

    /**
	*  @description inserts error logs into the system
    // TODO: Refactor method into separate Util or Model class
	*/
	public static void createErrorLog(Exception e, String filename) {
		try{
			Avodaas_Logs__c log = new Avodaas_Logs__c(Field_Name__c = '', Object_Name__c = '', Record__c = '', Line_Number__c = '', Error_Message__c = '', Field_Type__c = '');
			String operator = '';
			Schema.DescribeFieldResult sobField;
			log.Error_Type__c = e.getTypeName();
			switch on log.Error_Type__c {
				when 'System.DmlException' {
					for(Integer i = 0; i < e.getNumDml(); i++){
						log.Field_Name__c += operator + String.join(e.getDmlFieldNames(i), '|');
						if(e.getDmlId(i) != null){
							Id dmlId = e.getDmlId(i);
							log.Record__c += operator + dmlId;
							log.Object_Name__c = dmlId.getSObjectType().getDescribe().getName();
						}
						log.Line_Number__c += operator + e.getDmlIndex(i);
						log.Field_Type__c += operator + String.join(ApxUtil.getFieldTypes(e.getDmlFields(i)), '|');
						log.Error_Message__c += operator + e.getDmlMessage(i);
						operator = '|';
					}
				}
				when else {
					log.Error_Message__c = e.getMessage();
					log.Line_Number__c = String.valueOf(e.getLineNumber());
				}
			}
			log.Stack_Trace__c = e.getStackTraceString();
			log.User__c = userinfo.getUserId();
			log.File_Name__c = filename;
			List<String> customFields = ApxUtil.getCustomFieldsForSObject('Avodaas_Logs__c');
			Map<String, Schema.DescribeFieldResult> logFields = ApxUtil.getSObjectDescribeFields('Avodaas_Logs__c');
			for(String field :customFields){
				if(!logFields.containsKey(field)) continue;
				sobField = logFields.get(field);
				Integer fieldLen = ApxUtil.getFieldLength(sobField);
				if(string.valueOf(log.get(field)).length() > fieldLen){
					String fieldVal = string.valueOf(log.get(field));
					log.put(field, fieldVal.substring(0, fieldLen - 1));
				}
			}
			insert log;
		}catch(Exception ex){
			String message = 'ApxUtil.errorLogs => the error:' + ex.getMessage() + '\r\nStack Trace: ' + ex.getStackTraceString();
			ApxUtil.sendAdminEmail('Error inserting Log Tracking', message);
			System.debug(message);
		}
	}


    public static void createErrorLog(String strEx, String filename) {
        try{
            Avodaas_Logs__c log = new Avodaas_Logs__c(File_Name__c = filename, Error_Message__c = strEx, User__c = userinfo.getUserId());
            insert log;
        }catch(Exception ex){ Apx.sendAdminEmail('Error inserting Log Tracking', 'ApxUtil.createErrorLog => the error:' + ex.getMessage() + '\r\nStack Trace: ' + ex.getStackTraceString());
            System.debug('ApxUtil.createErrorLog => the error:' + ex.getMessage() + '\r\nStack Trace: ' + ex.getStackTraceString());
        }
    }

    /**
     *  @description Sends an email to the default admin email addresses
     */
    public static void sendAdminEmail(String subject, String msg) {
        sendEmail(ADMIN_EMAILS, subject, msg);
    }

      /**
     *  @description Sends an email to the specified email addresses
     */
    public static void sendEmail (String[] toAddresses, String subject, String msg) {
        Messaging.SingleEmailMessage mail = setUpEmail(toAddresses, subject, msg);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    /**
     * Create a Messaging.SingleEmailMessage object
     * @params List of to Email Addresses, Subject, Message
     * @returns Messaging.SingleEmailMessage
     */
    public static Messaging.SingleEmailMessage setUpEmail(String[] toAddresses, String subject, String msg){
        return setUpEmail(toAddresses, subject, msg, null);
    }

     /**
	*  @description get a list of fields and returns a list of field types
	*/
	public static List<String> getFieldTypes(List<Schema.SObjectField> fields){
		Set<String> types = new Set<String>();
		for(Schema.SObjectField sobField : fields) types.add(sobField.getDescribe().getType().name());
		return new List<String>(types);
	}
    
    /**
     * @description A custom error string that compiles all the exception's error information into one string
     **/
    public static String longErrorString(System.Exception e) {
        return 'Message: ' + e.getMessage() + ', Cause: ' + e.getCause() + ', Type: ' + e.getTypeName() + ', Line Number: ' + e.getLineNumber() + ', Stack Trace: ' + e.getStackTraceString();
    }


    /**
     * Create a Messaging.SingleEmailMessage object
     * @params List of to Email Addresses, Subject, Message, List of cc Addresses
     * @returns Messaging.SingleEmailMessage
     */
    public static Messaging.SingleEmailMessage setUpEmail(String[] toAddresses, String subject, String msg, String[] ccAddresses){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setReplyTo(ADMIN_REPLYTO_EMAIL);
        mail.setSenderDisplayName(ADMIN_SENDER_DISPLAYNAME);
        mail.setSubject(subject);
        mail.setPlainTextBody(msg);
        if(ccAddresses != null && !ccAddresses.isEmpty()) mail.setCcAddresses(ccAddresses);
        return mail;
    }


    public static final Map<String, Schema.SObjectType> cachedGlobalDescribe{
        get{
            if(cachedGlobalDescribe == null){
                 cachedGlobalDescribe = Schema.getGlobalDescribe();
            }
            return cachedGlobalDescribe;
        } private set;
    }

	public static final Map<String, Schema.DescribeSObjectResult> cachedGlobalDsrs{
		get {
			if (cachedGlobalDsrs == null) {
				cachedGlobalDsrs = new Map<String,Schema.DescribeSObjectResult>();
				List<Schema.DescribeSObjectResult> objects = Schema.describeSObjects(New List<String>(cachedGlobalDescribe.keySet()));
				for(Schema.DescribeSObjectResult sdSoj : objects) cachedGlobalDsrs.put(sdSoj.getName(), sdSoj);
			}
			return cachedGlobalDsrs;
		} private set;
	}


    /**
     * @description Get Describe Sobject Result
     * @param String object api name
     * @return Describe SObject result or null if it doesn't exist
     */
    public static Schema.DescribeSObjectResult getSObjectDescribeResult(String objectAPIName){
        try{
            if(cachedGlobalDsrs.containsKey(objectAPIName)) return cachedGlobalDsrs.get(objectAPIName);
            else return null;
        } catch(System.InvalidParameterValueException e){
            //object doesn't exist
            return null;
        }
    }

        /***
     * @description Get a map of sobject field API Names to the actual SObjectField object
     * @param String object api name
     * @return Map of field api names & SObjectField objects
     */
    public static Map<String, Schema.SObjectField> getSObjectFields(String objectAPIName){
        Schema.DescribeSObjectResult describeResult = getSObjectDescribeResult(objectAPIName);
        if(describeResult == null) return null;
        Map<String, Schema.SObjectField> fields = new Map<String, Schema.SObjectField>();
        Map<String, Schema.SObjectField> objFields = describeResult.fields.getMap();
        Schema.DescribeFieldResult dfr;
        for(Schema.SObjectField field: objFields.values()){
            dfr = field.getDescribe();
            fields.put(dfr.getName(), field);
        }
        return fields;
    }

        /***
     * @description Get a sobject and returns a map of the fields with there Schema.DescribeFieldResult
     * @param String object api name
     * @return Map of field api names & DescribeFieldResult
     */
    public static Map<String,Schema.DescribeFieldResult> getSObjectDescribeFields(String objectAPIName){
        Schema.DescribeSObjectResult describeResult = getSObjectDescribeResult(objectAPIName);
        if(describeResult == null) return null;
        Map<String, Schema.DescribeFieldResult> fields = new Map<String, Schema.DescribeFieldResult>();
        Map<String, Schema.SObjectField> objFields = describeResult.fields.getMap();
        Schema.DescribeFieldResult dfr;
        for(Schema.SObjectField field: objFields.values()){
            dfr = field.getDescribe();
            fields.put(dfr.getName(), dfr);
        }
        return fields;
    }

     /****
     * @description Get Object name from a record id
     * @param RecordId
     * @return Object Name
     */
    @AuraEnabled(cacheable=true)
    public static String getObjectNameById(Id recordId){
        return recordId.getSObjectType().getDescribe().getName();
    }



    /**
	*  @description Accepts a field object and returns the number of characters allowed
	*/
	public static Integer getFieldLength(DescribeFieldResult fieldDescription){
		return fieldDescription.getLength();
	}

    /**
     * Check if SObject by given name exists in org
     * https://gist.github.com/nigamgoyal/b5ec5e3dc5350182c938792a20401683
     */
    public static Boolean isSObject(String objectNameParam){
        for (Schema.SObjectType sObjectType : cachedGlobalDescribe.values()) {
           String sobjName = String.valueOf(sObjectType);
           if (sobjName.equalsIgnoreCase(objectNameParam)) return true;
        }
        return false;
    }

    /**
    * Check if field by given name exists on given SObject
    */
    public static Boolean isSObjectAndfieldExists(String sObjectName, String fieldName){
        if(!isSObject(sObjectName)) return false;
        //special case
        if(fieldName == 'Name') return true;
        try{
            if(!cachedGlobalDescribe.containsKey(SObjectName)) return false;
            Schema.DescribeSObjectResult objResult = getSObjectDescribeResult(SObjectName);
            if(objResult == null) return false;
            return objResult.fields.getMap().keySet().contains(fieldName.toLowerCase());
        }catch(Exception e){
            return false;
        }
    }

    /**
    * @description
    * gets an object name and a field type and returns all the fields on the object that their type = field type
    **/
    public static List<String> getSObjectFieldsForObjectByType(String objName, String fieldType){
        List<String> fields = new List<String>();
        SObjectType sobjType = Schema.getGlobalDescribe().get(objName);
        Schema.DescribeSObjectResult dfrLkp = sobjType.getDescribe();
        for(schema.SObjectField sotype : dfrLkp.fields.getMap().values()){
            Schema.DescribeFieldResult fieldDescObj = sotype.getDescribe();
            if(fieldDescObj.getType().name() == fieldType){
                fields.add(fieldDescObj.getName()); // api field name
            }
        }
        return fields;
    }

        /*
    *  @description the function gets a List of Database.Error and preps the log record.
    * @params List Of DML Results, fileName, objectName, list of record Ids that were attempted to update.
    * @returns Avodaas_Logs__c record
    */
    public static Avodaas_Logs__c prepErrorLog(List<Database.Error> errors, String filename, String objectName, List<Id> ids) {
        try{
            Avodaas_Logs__c log = new Avodaas_Logs__c(Error_Type__c = 'System.DmlException', Object_Name__c = objectName, User__c = userinfo.getUserId(), File_Name__c = filename);
            String operator = '';
            log.Error_Message__c = (ids != null && !ids.isEmpty()) ? String.join(ids,' ,') + ' | ' : '';
            if(!errors.isEmpty()){
                Database.Error dbErr = errors.get(0);
                log.Field_Name__c = String.join(dbErr.getFields(),' | ');
                log.Error_Message__c = dbErr.getMessage();
                List<Schema.SObjectField> sObjectfields = ApxUtil.getSObjectFieldsByNames(objectName, dbErr.getFields());
                log.Field_Type__c = String.join(ApxUtil.getFieldTypes(sObjectfields), '|');
            }
            log = (Avodaas_Logs__c) trimLongValuesForRecord(log, 'Avodaas_Logs__c');
            return log;
        } catch(Exception ex){
            String message = 'ApxUtil.createErrorLog => the error:' + ex.getMessage() + '\r\nStack Trace: ' + ex.getStackTraceString();
            sendAdminEmail('Error inserting Log Tracking', message);
            System.debug(message);
            return null;
        }
    }

    public static SObject trimLongValuesForRecord(SObject rec, String objectName){
        Schema.DescribeFieldResult sobField;
        List<String> customFields = ApxUtil.getCustomFieldsForSObject(objectName);
        Map<String, Schema.DescribeFieldResult> sFields = ApxUtil.getSObjectDescribeFields(objectName);
        for(String field : sFields.keySet()){
            sobField = sFields.get(field);
            if(sobField.getType() != Schema.DisplayType.String && sobField.getType() != Schema.DisplayType.TextArea) continue;
            Integer fieldLen = ApxUtil.getFieldLength(sobField);
            if(fieldExist(rec, field) && rec.get(field) != null && string.valueOf(rec.get(field)).length() > fieldLen){
                String fieldVal = string.valueOf(rec.get(field));
                rec.put(field, fieldVal.substring(0, fieldLen - 1));
            }
        }
        return rec;
    }

    public static Boolean fieldExist(SObject rec, String fieldName){
        Map<String, Object> fieldToValue = rec.getPopulatedFieldsAsMap();
        return fieldToValue.containskey(fieldName);
    }

    public static List<Schema.SObjectField> getSObjectFieldsByNames(String objectName, List<String> fieldNames){
        Map <String, Schema.SObjectField> fieldMap = ApxUtil.getSObjectFields(objectName);
        List<Schema.SObjectField> fields = new List<Schema.SObjectField> ();
        for(String field : fieldMap.keyset()){
            if(fieldNames.contains(field)) fields.add(fieldMap.get(field));
        }
        return fields;
    }


    // the fucntions gets a list of LeadConvertResult and logs down all the conversions that faild
    public static String AvodaasLogsLcrErrors(List<Database.LeadConvertResult> lcrs) {
        String errMsg = '';
        Avodaas_Logs__c log;
        List<Avodaas_Logs__c> errorLogs = new List<Avodaas_Logs__c>();
        for (Database.LeadConvertResult lcr : lcrs){
            if (lcr.isSuccess()) continue;
            log = prepErrorLog(lcr.getErrors(),CLASS_NAME, 'Lead', new List<Id>{lcr.getLeadId()});
            if(log != null) errorLogs.add(log);
            for (Database.Error error : lcr.getErrors()) errMsg += 'Status: ' + error.getStatusCode() + ', Error msg: ' + error.getMessage() + ' \n\n';
        }
        if(!errorLogs.isEmpty()) insert errorLogs;
        ApxUtil.sendAdminEmail('ApxUtil::AvodaasLogsLcrErrors', errMsg);
        return errMsg;
    }


    // DisplayType Enum: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_enum_Schema_DisplayType.htm
    /**
     *	@description Translates a SObject field into the string version of the SOQL where clause
     *	@param json - Coming from lightning, like: $A.util.json.encode(component.get("v.contact")) or JSON.stringify(vcontact)
     *	@return Ex:  " IsActive = false "  |  " MultiSelect__c includes ('Option1','Option2') "
     */
    public static String toWhereClause(String sObjectName, String fieldName, Object value) {
        // Get the field map for the sobjectType (Ex: 'Contact')
        Map<String, Schema.SObjectField> fieldMap = cachedGlobalDsrs.containsKey(sObjectName) ? cachedGlobalDsrs.get(sObjectName).fields.getMap() : null;
        if(fieldMap == null) return ' ';
        String whereClause = ' ';
        if (fieldName != 'sobjectType' && fieldMap.get(fieldName) != null) {
            //Get data types for the fieldName, and build whereClause based on the field type
            Schema.DisplayType fieldDataType = fieldMap.get(fieldName).getDescribe().getType();

            // Converting object to String
            String val = String.escapeSingleQuotes('' + value);
            if(fieldDataType == Schema.DisplayType.Boolean) {
                if (val == 'Yes') val = 'true';
                if (val == 'No') val = 'false';
                whereClause += fieldName + ' = ' + val;

            } else if(fieldDataType == Schema.DisplayType.Picklist) {
                if(!val.contains(';')) whereClause += fieldName + ' = \'' + val + '\' ';
                else {
                    List<String> eachOption = val.substringBeforeLast('|').split(';');
                    whereClause += ' (';
                    for (String option : eachOption) {
                        whereClause += fieldName + ' = \'' + option + '\' OR ';
                    }
                    whereClause = whereClause.removeEnd(' OR ') + ')';
                }
            } else if(fieldDataType == Schema.DisplayType.MultiPicklist) {
                String operator = val.substringAfterLast('|');		// Operator AND or OR saved as the last value in the multipicklists
                String values = val.substringBeforeLast('|');
                if (operator == null || String.isBlank(operator) || operator == 'OR') {
                    List<String> eachOption = val.substringBeforeLast('|').split(';');
                    whereClause += fieldName + ' includes (';
                    for (String option : eachOption) {
                        whereClause += '\'' + option + '\',';
                    }
                    whereClause = whereClause.removeEnd(',');
                    whereClause += ') ';
                } else if (operator == 'AND') {
                    String options = val.substringBeforeLast('|');
                    whereClause += fieldName + ' includes (\'' + options + '\') ';		// This was an exact match => //fieldName + ' = \'' + options + '\' ';
                }

            } else if(fieldDataType == Schema.DisplayType.Date) {
            } else if(fieldDataType == Schema.DisplayType.DateTime) {
            } else if(fieldDataType == Schema.DisplayType.Double || fieldDataType == Schema.DisplayType.CURRENCY || fieldDataType == Schema.DisplayType.INTEGER) {
                // Allowing for number ranges!
                if (val.contains('-')) {
                    String numBefore = val.substringBefore('-');
                    String numAfter = val.substringAfter('-');
                    whereClause += fieldName + ' >= ' + numBefore + ' AND ' + fieldName + ' <= ' + numAfter + ' ';
                } else if (val.contains('<')) {
                    String num = val.substringAfter('<');
                    whereClause += fieldName + ' <= ' + num + ' ';
                } else if (val.contains('>')) {
                    String num = val.substringAfter('>');
                    whereClause += fieldName + ' >= ' + num + ' ';
                } else {
                    whereClause += fieldName + ' = ' + val + ' ';
                }
            } else if(fieldDataType == Schema.DisplayType.ID) {
                if (val.startsWith('(')) {
                    // We have a list of ids.  Search across all these ids
                    System.debug('  val before escaping: ' + val);
                    System.debug('  val AFTER escaping: ' + String.escapeSingleQuotes(val));
                    whereClause += fieldName + ' in ' + val.remove('\\') + ' ';
                } else {
                    whereClause += fieldName + ' = \'' + val + '\' ';
                }
            } else if(fieldDataType == Schema.DisplayType.Phone) {
                String last4digits = val.substringAfterLast('-');
                whereClause += fieldName + ' like \'%' + ((String.isEmpty(last4digits)) ? val : last4digits) + '%\' ';
            } else if(fieldDataType == Schema.DisplayType.Reference) {
                whereClause += fieldName + ' = \'' + val + '\' ';
            } else if(fieldDataType == Schema.DisplayType.String || fieldDataType == Schema.DisplayType.EMAIL) {
                if (val.contains(';') && val.contains('|')) {
                    // Has format (like on Doctor_Category__c coming from the Doctor RSP) 'PSY;SW|OR'
                    //   - This is usually for picklists, but here we want to convert to regular string search
                    val = val.replaceAll(';', ',').substringBeforeLast('|');
                }
                if (val.contains(',')) {
                    whereClause += '(';
                    List<String> vals = val.split(',');
                    for (String searchText : vals) {
                        whereClause += fieldName + ' like \'' + searchText.trim() + '%\' OR ';
                    }
                    whereClause = whereClause.removeEnd('OR ') + ') ';
                } else {
                    whereClause += fieldName + ' like \'' + val + '%\' ';	// Only want wild card on last part  ///' like \'%' + val + '%\' ';
                }
            } else if(fieldDataType == Schema.DisplayType.TextArea) {
                whereClause += fieldName + ' like \'%' + val + '%\' ';
            } else if(fieldDataType == Schema.DisplayType.Time) {
            } else if(fieldDataType == Schema.DisplayType.URL) {
            }
        }

        return whereClause;
    }

}