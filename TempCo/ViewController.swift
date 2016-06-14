//
//  ViewController.swift
//  TempCo
//
//  Created by Tarvo Mäesepp on 14/05/16.
//  Copyright © 2016 Tarvo Mäesepp. All rights reserved.
//

import UIKit
import Contacts
import JSSAlertView

class ViewController: UIViewController, UITextFieldDelegate {
    
    //**VARIABLES FROM STORYBOARD**\\
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var deadlinePicker: UIDatePicker!
    @IBOutlet weak var addContactButton: UIButton!
    
    
    let localNotification = UILocalNotification()
    var defaults = NSUserDefaults.standardUserDefaults()
    var contacts:[NSString] = []
    
    var contactStore = CNContactStore()
    var updateContact = CNContact()
    var isUpdate: Bool = false
    
    //**VIEWDIDLOAD FUNCTION**\\
    override func viewDidLoad() {
        super.viewDidLoad()

        style()
        
        //Touch outside field hides keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        //Return key hides keyboard
        self.nameField.delegate = self
        self.phoneField.delegate = self
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contactDelete:", name: DELETECONTACT, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dislikeActionButtonTapped:", name: KEEPCONTACT, object: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //**ASK FOR CONTACTS ACCESS PERMISSION FUNCTION**\\
    func askForContactAccess() {
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        
        switch authorizationStatus {
        case .Denied, .NotDetermined:
            self.contactStore.requestAccessForEntityType(CNEntityType.Contacts, completionHandler: { (access, accessError) -> Void in
                if !access {
                    if authorizationStatus == CNAuthorizationStatus.Denied {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let message = "\(accessError!.localizedDescription)\n\nPlease allow the app to access your contacts through the Settings."
                            let alertController = UIAlertController(title: "Contacts", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                            
                            let dismissAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action) -> Void in
                            }
                            
                            alertController.addAction(dismissAction)
                            
                            self.presentViewController(alertController, animated: true, completion: nil)
                        })
                    }
                }
            })
            break
        default:
            break
        }
    }
    
    
    //**"ADD CONTACT" BUTTON AND IT'S ACTION FUNCTION**\\
    @IBAction func addContact(sender: AnyObject) {
        
        askForContactAccess()
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        let dateString = dateFormatter.stringFromDate(deadlinePicker.date)
        
        
        var newContact = CNMutableContact()
        
        if isUpdate == true {
            newContact = updateContact.mutableCopy() as! CNMutableContact
        }
        
        //Set Name
        newContact.givenName = nameField.text!
        
        //Set Phone No
        let phoneNo = CNLabeledValue(label:CNLabelPhoneNumberMobile, value:CNPhoneNumber(stringValue:phoneField.text!))
        
        if isUpdate == true {
            newContact.phoneNumbers.append(phoneNo)
        } else {
            newContact.phoneNumbers = [phoneNo]
        }
        
        var message: String = ""
        
        do {
            let saveRequest = CNSaveRequest()
            if isUpdate == true {
                saveRequest.updateContact(newContact)
                message = "Contact Updated Successfully"
            } else {
                if authorizationStatus == CNAuthorizationStatus.Authorized{
                saveRequest.addContact(newContact, toContainerWithIdentifier: nil)
                contacts.append(nameField.text!)
                defaults.setObject(contacts, forKey: "key")
                print(contacts)
                
                    //Alert for asuccessfully adddd contact
                let alertview = JSSAlertView().show(self, title: "Success", text: "Contact added successfully and will be deleted on " + dateString, buttonText: "Cool", color: UIColor.init(red: 0.196, green:0.200, blue:0.200, alpha: 1))
                
                alertview.setTextTheme(.Light)
                    
                    let userInfo = ["url" : "Hello"]
                    
                    //Set notification
                    LocalNotificationHelper.sharedInstance().scheduleNotificationWithKey("TempCo", title: "see options(left)", message:nameField.text!+"Your contact needs to be deleted!", date: deadlinePicker.date, userInfo: userInfo)
                    
                }

            }
            
            let contactStore = CNContactStore()
            try contactStore.executeSaveRequest(saveRequest)
            
             
        }
        catch {
            if isUpdate == true {
                message = "Unable to Update the Contact."
            } else {
                if authorizationStatus == CNAuthorizationStatus.Denied {
                    
                    let alertview = JSSAlertView().show(self, title: "Oops!", text: "Unable to add the new Contact, check contact permission from Settings.", buttonText: "Check it", cancelButtonText: "Nope", color: UIColor.init(red: 0.216, green:0.043, blue:0.129, alpha: 1))
                    alertview.addAction(openSettings)
                    alertview.setTextTheme(.Light)

                }
            }
            
            
        }

    }
    
    //**DELETE CONTACT FUNCTION**\\
    func contactDelete(notification : NSNotification){
        var contacts = defaults.objectForKey("key") as? [String] ?? [String]()
        let predicate = CNContact.predicateForContactsMatchingName(contacts[0])
        contacts.removeAtIndex(0)
        
        
        let toFetch = [CNContactEmailAddressesKey]
        
        defaults.setObject(contacts, forKey: "key")
        
        
        
        do{
            let contacts = try contactStore.unifiedContactsMatchingPredicate(predicate,keysToFetch: toFetch)
            guard contacts.count > 0 else{
                let alertview = JSSAlertView().show(self, title: "Oops!", text: "We couldn't remove your contact right now, please remove it manualy :(", buttonText: "OK", color: UIColor.init(red: 0.216, green:0.043, blue:0.129, alpha: 1))

                alertview.setTextTheme(.Light)
                
                return
            }
            
            guard let contact = contacts.first else{
                
                return
            }
            
            let req = CNSaveRequest()
            let mutableContact = contact.mutableCopy() as! CNMutableContact
            req.deleteContact(mutableContact)
            
            do{
                try contactStore.executeSaveRequest(req)
                let alertview = JSSAlertView().show(self, title: "Success", text: "Contact is successfully removed from Contacts!", buttonText: "Awesome!", color: UIColor.init(red: 0.196, green:0.200, blue:0.200, alpha: 1))
                
                alertview.setTextTheme(.Light)
                //SCLAlertView().showNotice("Success", subTitle:"Contact is removed from contacts!")
                print("Success, You deleted the user")
                print(contacts)
            } catch let e{
                print("Error = \(e)")
            }
        } catch let err{
            print(err)
        }
        print(contacts)
    }
    
    
    
    //**RETURN KEY FUNCTION**\\
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    //**DISSMISS KEYBOARD FUNCTION*\\
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    //**STYLE**\\
    func style(){
        
        //Gradient background
        let topColor = UIColor(red: 0.051, green: 0.063, blue: 0.075, alpha: 1.00)
        
        let bottomColor = UIColor(red: 0.188, green: 0.227, blue: 0.259, alpha: 1.00)
        
        let gradientColors: [CGColor] = [topColor.CGColor, bottomColor.CGColor]
        let gradientLocations: [Float] = [0.0, 1.0]
        
        let gradientLayer: CAGradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientColors
        gradientLayer.locations = gradientLocations
        
        gradientLayer.frame = self.view.bounds
        self.view.layer.insertSublayer(gradientLayer, atIndex: 0)
        
        //NameField & PhoneField decoration
        nameField.layer.cornerRadius = 0
        nameField.layer.masksToBounds = true
        nameField.layer.borderColor = UIColor.init(red: 0.239, green: 0.867, blue: 0.796, alpha: 1.00).CGColor
        nameField.layer.borderWidth = 2.0
        
        phoneField.layer.cornerRadius = 0
        phoneField.layer.masksToBounds = true
        phoneField.layer.borderColor = UIColor.init(red: 0.239, green: 0.867, blue: 0.796, alpha: 1.00).CGColor
        phoneField.layer.borderWidth = 2.0
        
        //Button decoration
        let borderAlpha : CGFloat = 0.7
        let cornerRadius : CGFloat = 0
        
        addContactButton.frame = CGRectMake(100, 100, 200, 40)
        addContactButton.backgroundColor = UIColor.clearColor()
        addContactButton.layer.borderWidth = 1.0
        addContactButton.layer.borderColor = UIColor(red: 0.992, green:0.090, blue:0.557, alpha: borderAlpha).CGColor
        addContactButton.layer.cornerRadius = cornerRadius
        
        //DeadlinePicker decoration
        deadlinePicker.setValue(UIColor.whiteColor(), forKeyPath: "textColor")
        deadlinePicker.datePickerMode = .CountDownTimer
        deadlinePicker.datePickerMode = .DateAndTime
        
        
    }
    
    func openSettings(){
        UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
    }
    
}
