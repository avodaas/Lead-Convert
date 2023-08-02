import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//general useful definitions
const SUCCESS = 'success';
const ERROR = 'error';


/**
 * @description: Display toast message
 * @name showToastMessage
 * @params The LWC object, String title for message, String message, String variant
 *          Legal values: SUCCESS, ERROR
 * @returns: none
 * */
function showToastMessage(lwc, title, message, variant){
    lwc.dispatchEvent(
        new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        })
    );
}
/**
 * @description: add months to a given date
 * @name addMonths
 * @params Date curDate, Integer months
 * @returns: date 
 * */
 function addMonths(curDate, months) {
    let d = curDate.getDate();
    curDate.setMonth(curDate.getMonth() + +months);
    if (curDate.getDate() != d) {
        curDate.setDate(0);
    }
    return curDate;
}

/**
 * @description: formats a Date to to sf date yyyy-mm-dd
 * @name formatDate
 * @params Date date
 * @returns: String 
 * */
 function formatDate(curDate) {
    let month = '' + (curDate.getMonth() + 1);
    let day = '' + curDate.getDate();
    let year = curDate.getFullYear();

    if (month.length < 2)
        month = '0' + month;
    if (day.length < 2)
        day = '0' + day;
    return [year, month, day].join('-');
}

/**
 * @description: checks if all the html elements of a specific type on the page are valid.
 * @name formValid
 * @params The LWC object, the html elemnt
 * @returns: Boolean 
 * */
function formValid(lwc, elementType){
   return [...lwc.template.querySelectorAll(elementType)]
        .reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return (validSoFar && inputField.checkValidity());
        }, true);
}








export {SUCCESS, ERROR, showToastMessage, addMonths, formatDate, formValid};