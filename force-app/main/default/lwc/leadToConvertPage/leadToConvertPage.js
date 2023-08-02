import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class LeadToConvertPage extends  NavigationMixin(LightningElement) {
    @api recordId;

    @api invoke() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__LeadConvertAccess',
            },
            state: {
                c__recordId: this.recordId
            }
        });
    }
}