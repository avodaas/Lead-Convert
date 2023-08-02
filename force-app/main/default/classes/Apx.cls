/**
 *  Apx
 *  @description Utility class for common methods
 *  @testclass  Apx_Test.cls
 *  @author HGolov
 *  @date   Aug 2020
 */
global without sharing class Apx {
    //========== Static Variables =========//
    public static final String ADMIN_REPLYTO_EMAIL = 'fusion-admin@avodaas.com';
    public static final String ADMIN_SENDER_DISPLAYNAME = 'The orgname';

    public static final String MANAGEMENT_EMAIL = 'admin@theorg.com';
    
    public static List<String> ADMIN_EMAILS{
        get{
            if(ADMIN_EMAILS == null){
                ADMIN_EMAILS = new List<String>{'fusion-admin@avodaas.com'};
            }
            return ADMIN_EMAILS;
        }
        set;
    } 



    /**
     *  @description Sends an email to the default admin email addresses
     */
    public static void sendAdminEmail (String subject, String msg) {
        sendEmail(ADMIN_EMAILS, subject, msg);
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

    /**
     * Create a Messaging.SingleEmailMessage object 
     * @params List of to Email Addresses, Subject, Message
     * @returns Messaging.SingleEmailMessage
     */
    public static Messaging.SingleEmailMessage setUpEmail(String[] toAddresses, String subject, String msg){
        return setUpEmail(toAddresses, subject, msg, null);
    }
   

    /**
     *  @description Sends an email to the specified email addresses
     */
    public static void sendEmail (String[] toAddresses, String subject, String msg) {
        Messaging.SingleEmailMessage mail = setUpEmail(toAddresses, subject, msg);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

}