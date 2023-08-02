/**
 *	
 *	  @description SoslUtil class for sosls. 
 *	  @author Avodaas
 *	  @date	july 2022
 */

public with sharing class SoslUtil {

    public static final List<String> SOSL_RETURN_TYPES = new List<String>{ 'NAME',  'EMAIL','PHONE' , 'ALL'};
    public static final Integer DEFAULT_SEARCH_RESULTS_LIMIT = 20;
    public static final String CLASS_NAME = SoslUtil.class.getName();

    public class SoslProperty {
        public String searchString;
        public String fieldType;
        public Integer recordLimit;
        public Map<String, List<String>> fieldsByObject;

        public SoslProperty(String searchString, String fieldType, Map<String, List<String>> fieldsByObject, Integer recordLimit){
            this.searchString = searchString;
            this.fieldType = fieldType;
            this.fieldsByObject = fieldsByObject;
            this.recordLimit = recordLimit == null ? DEFAULT_SEARCH_RESULTS_LIMIT : recordLimit ;
        }

        public Boolean isValid(){
            return  String.isNotBlank(searchString) && searchString.length() >= 3 && String.isNotBlank(fieldType) && SOSL_RETURN_TYPES.contains(fieldType.toUpperCase())
            && fieldsValidByObject(fieldsByObject);
         }

        public Boolean fieldsValidByObject(Map<String, List<String>> fieldsByObject){
            List<String> fields = new  List<String>();
            List<String> fieldsToRemove = new List<String>();
            Set<String> fieldsSet;
            if(fieldsByObject.isEmpty()) return false;
            for(String objName : fieldsByObject.keySet()){
                if(!ApxUtil.isSObject(objName)) return false;
                fields = fieldsByObject.get(objName);
                if(fields.isEmpty()) return false;
                for(String field : fields) if(field.contains('.')) fieldsToRemove.add(field);
                if(!fieldsToRemove.isEmpty()){
                    fieldsSet = new Set<String>(fields);
                    fieldsSet.removeAll(fieldsToRemove);
                    fields = new List<String>(fieldsSet);
                }
                if(ApxUtil.getSObjectFieldsByNames(objName, fields).size() != fields.size()) return false; // if one one the objects has a wrong field name return false
            }
            return true;
        }
    }

    public class SoslResult{
        public List<List<SObject>> soslResults;
        public SoslResult (List<List<SObject>> soslResults) {
            this.soslResults = soslResults;
        }

        public List<SObject> getResults(String sobjectType){ // Returns List<SObject> for the specified type
           for(List<SObject> records : soslResults){
           if(records.isEmpty()) continue;
                if(sobjectType == ApxUtil.getObjectNameById(records[0]?.Id)) return records;
           }
           return new List<SObject>();
        }

        public List<List<SObject>> getAllResults() {// Returns the raw List<List<SObject>>
            return soslResults;
        }
    }

    public static SoslResult getSOSLRecords(String searchString, String fieldType, String objectName, List<String> fields, Integer recordLimit){
        SoslResult soslRes;
        Map<String, List<String>> fieldsByObject = new  Map<String, List<String>>();
        if(String.isEmpty(objectName) || fields.isEmpty()) return soslRes;
        fieldsByObject.put(objectName, fields);
        return getSOSLRecords(searchString, fieldType, fieldsByObject, recordLimit);
    }
        
    public static SoslResult getSOSLRecords(String searchString, String fieldType, Map<String, List<String>> fieldsByObject, Integer recordLimit){
        SoslResult soslRes;
        try{
            SoslProperty soslPRP = new SoslProperty(searchString, fieldType, fieldsByObject, recordLimit);
            if(!soslPRP.isValid()) return soslRes;
            String returningString = '', soslQuery, searchStringForSOSL;
            List<String> fields;
            for(String objName : soslPRP.fieldsByObject.keySet()){
                fields =  soslPRP.fieldsByObject.get(objName);

                returningString += objName + '(';
                for(String field : fields) returningString += field + ',';
                returningString = returningString.removeEnd(',');
                returningString += '),';
            }
            returningString = returningString.removeEnd(',');
            try{
                searchStringForSOSL = '\'*' + string.escapeSingleQuotes(soslPRP.searchString) + '*\'';
                soslQuery = 'FIND ' + searchStringForSOSL + ' IN ' + soslPRP.fieldType.toUpperCase() + ' FIELDS RETURNING '
                                +  returningString +' LIMIT ' + recordLimit ;
                System.debug('SOSL QUERY: ' + soslQuery);
                soslRes = new SoslResult(Search.query(soslQuery));
            }catch(System.QueryException qe){
                ApxUtil.sendAdminEmail('Error in SoslUtil Class sosl on' + soslPRP.fieldsByObject.keyset(), ' Error Message:' + qe.getMessage());
                ApxUtil.createErrorLog(qe, CLASS_NAME);
                return soslRes;
                }
            }
            catch(Exception ex){
                ApxUtil.sendAdminEmail('Error in SoslUtil Class',  'Error Message:'+ ApxUtil.longErrorString(ex));
                ApxUtil.createErrorLog(ex, CLASS_NAME);
            }
            return soslRes;
        }
    }