import { LightningElement, api } from 'lwc';

export default class CustomRadioButton extends LightningElement {
    @api option1;
    @api option2;
    @api typeobj;
    @api disableoption;
    @api checkedop1 = false;
    @api checkedop2 = false;
    @api hideOption2 = false;

    changeval(event){
      let val = event.target.value;
      let sendDetails = {'typeobj' : this.typeobj, 'option' :val};
      const selectEvent = new CustomEvent('selected', {
        detail: sendDetails,  
        bubbles: true,  
        composed: true  
      });  
      // Fire the custom event  
      this.dispatchEvent(selectEvent);
    }
}