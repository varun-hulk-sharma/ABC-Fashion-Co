import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

// APEX METHODS
import validateToken from '@salesforce/apex/GuestProfileAuthenticationController.validateToken';
import updateCustomerProfile from '@salesforce/apex/GuestProfileAuthenticationController.updateCustomerProfile';

// ACCOUNT OBJECT
import ACCOUNT_OBJECT from '@salesforce/schema/Account';

// ACCOUNT FIELDS
import SHOE_SIZE_FIELD from '@salesforce/schema/Account.Shoe_Size__c';
import TSHIRT_SIZE_FIELD from '@salesforce/schema/Account.T_Shirt_Size__c';

export default class GuestProfileAuthentication extends LightningElement {
    isLoading = true;
    _guestToken;
    isValidToken = false;
    missingRequiredFields = true;
    acctObj;

    phone = '';
    personBirthdate = '';
    shoeSize = '';
    tShirtSize = '';

    shoeSizeOptions = [];
    tShirtSizeOptions = [];

    recordTypeId;

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfoHandler({ data, error }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            console.error('error fetching Account Object info' + error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: SHOE_SIZE_FIELD
    })
    shoeSizeHandler({ data, error }) {
        if (data) {
            this.shoeSizeOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: TSHIRT_SIZE_FIELD
    })
    tShirtSizeHandler({ data, error }) {
        if (data) {
            this.tShirtSizeOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error(error);
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
          console.log('Token value:: ' + currentPageReference.state?.token);
          this.guestToken = currentPageReference.state?.token;
       }
    }

    get guestToken() {
        return this._guestToken;
    }

    set guestToken(value) {
        this._guestToken = value;

        if (value) {
            this.validateGuest();
        }
    }

    connectedCallback() {
        console.log('Component initiated');
    }    

    async validateGuest(){
        console.log('Begin guest token validation process...');
        try {
            this.acctObj = await validateToken({ profileToken: this._guestToken });
            console.log('acctObj:: ' + JSON.stringify(this.acctObj));

            this.phone = this.acctObj.Phone;
            this.personBirthdate = this.acctObj.PersonBirthdate;
            this.shoeSize = this.acctObj.Shoe_Size__c;
            this.tShirtSize = this.acctObj.T_Shirt_Size__c;

            if(!this.isBlank(this.personBirthdate) && !this.isBlank(this.shoeSize) && !this.isBlank(this.tShirtSize)){
                this.missingRequiredFields = false;
            }

            this.isValidToken = (this.acctObj !== null);
            console.log('isValidToken:: ' + this.isValidToken);
            this.isLoading = false;
        } catch (error) {
            console.error('error:: ' + error);
            this.isLoading = false;
        }
    }

    handleInputChange(event) {
        const { name, value } = event.target;
    
        if (name === 'phone') {
            
            this.phone = value;
        }
        else if (name === 'personBirthdate') {
            this.personBirthdate = value;
        }
        else if (name === 'shoeSize') {
            this.shoeSize = value;
        }
        else if (name === 'tShirtSize') {
            this.tShirtSize = value;
        }

        if(!this.isBlank(this.personBirthdate) && !this.isBlank(this.shoeSize) && !this.isBlank(this.tShirtSize)){
            this.missingRequiredFields = false;
        }
        else{
            this.missingRequiredFields = true;
        }
    }

    async handleSave(event){
        const phoneInput = this.template.querySelector('[data-id="phone"]');
        const phonePattern = /^[0-9]{10}$/;
        
        if (this.phone && !phonePattern.test(this.phone)) {
            phoneInput.setCustomValidity('Enter a valid phone number.');
        } else {
            phoneInput.setCustomValidity('');
        }

        phoneInput.reportValidity();

        if (!phoneInput.checkValidity()) {
            return;
        }

        this.isLoading = true;
        console.log('Begin profile update process...');
        try {
            await updateCustomerProfile({ profileToken: this._guestToken, phoneNumber: this.phone, bday: this.personBirthdate, shoeSize: this.shoeSize, tSize: this.tShirtSize });
            console.log('Save successful!');

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Your profile has bneen successfully updated',
                    variant: 'success'
                })
            );
            this.isLoading = false;
        } catch (error) {
            console.error('error:: ' + error);
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: error.body?.message,
                    variant: 'error'
                })
            );
            this.isLoading = false;
        }
    }

    isBlank(value) {
        return value == null || value.trim() === '';
    }
}