//
//  EventDetailViewController.swift
//  CheckedIn
//
//  Created by Ya Kao on 10/26/14.
//  Copyright (c) 2014 Group6. All rights reserved.
//

//Note: hiding first section header
//  Using the rest as seperator
import UIKit
import EventKit

class EventDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate {
    @IBOutlet weak var addToCalendarButton: UIBarButtonItem!
    var eventIdAndRsvped:NSDictionary?
    var eventObjectId:String?
    var thisEvent: ParseEvent!
    var RSVPstate:Bool?
    let eventStore = EKEventStore()
    let RSVPColor = UIColor(red: 63/255, green: 195/255, blue: 168/255, alpha: 1)
    let cancelColor = UIColor(red: 255/255, green: 193/255, blue: 126/255, alpha: 1)
    
    var checkedInState: Bool = false
    var checkInButton: UIButton!
    
    @IBOutlet weak var rsvpButton: UIButton!
    @IBOutlet weak var tableView: UITableView!    
    @IBOutlet weak var uiViewrsvpButton: UIView!
    var sectionKey = ["Header", "TimeInfo" ] //We can add more here
   
    //MARK: View Controller UI
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Event Detail"
         tableView.delegate = self
         tableView.dataSource = self
         tableView.rowHeight = UITableViewAutomaticDimension
         tableView.estimatedRowHeight = 96
        // Do any additional setup after loading the view.

        
        //if segue from profile view controller , otherwise, objectId should be set
         if self.eventIdAndRsvped != nil {
            self.eventObjectId = eventIdAndRsvped?.objectForKey("objectId") as String?
            if let rsvpState = eventIdAndRsvped?.objectForKey("isRsvped") as Bool? {
                self.RSVPstate = eventIdAndRsvped?.objectForKey("isRsvped") as Bool?
            }
            showRSVPButton()
        }
         fetchTheEvent()
    }
    
    //Check if we can check in into this event, display the check in button
    func canCheckIn()->Bool{
        if (RSVPstate == true) && (self.checkedInState == false) {

            var before12 = NSDate().dateByAddingTimeInterval(-60*60*12)
            var after12 = NSDate().dateByAddingTimeInterval(60*60*12)
            var compareBefore = before12.compare(thisEvent.eventDate!)
            var compareAfter = after12.compare(thisEvent.eventDate!)
            //println("compareBefore: \(compareBefore.rawValue), compareAfter: \(compareAfter.rawValue)")
            
            if compareBefore == NSComparisonResult.OrderedSame || compareBefore == NSComparisonResult.OrderedAscending{
                if compareAfter == NSComparisonResult.OrderedSame || compareAfter == NSComparisonResult.OrderedDescending{
                    println("Can check in the event!")
                    return true
                }else{
                    println("Can't check in yet")
                }
            }else{
                println("Can't check in yet")
            }
        }else{
            println("Cannot check in: RSVPstate is \(RSVPstate!), checkedInState is \(self.checkedInState)")
        }
        return false
        
    }
    
    //Check if this event is already checked in or not
    func checkedInStatus(){
        
        if(self.RSVPstate == false){
            self.checkedInState = false
        }else{

            var user = PFUser.currentUser()
            var relation = user.relationForKey("checkedIn")
            var events = ParseEvent.query() as PFQuery
            events.getObjectInBackgroundWithId(self.eventObjectId) { (object: PFObject!, error: NSError!) -> Void in
                if object != nil{
                    println("Already Checked in!!!! objectId: \(object.objectId), self.eventID: \(self.eventObjectId)")
                    //Already checked in, display something else
                    self.checkedInState = true
                    self.tableView.reloadData()

                }else{
                    println("Not checked in yet!")
                    self.checkedInState = false
                }
            }
        }


        
    }
    
    func checkInEvent(){
        println("Check in Event!")
        var user = PFUser.currentUser()
        var relation = user.relationForKey("checkedIn")
        var events = ParseEvent.query() as PFQuery
        events.getObjectInBackgroundWithId(self.eventObjectId) { (object: PFObject!, error: NSError!) -> Void in
            if object != nil{
                relation.addObject(object)
                user.saveEventually()
                self.checkedInState = true
                if(self.checkInButton != nil){
                    self.checkInButton.setImage(UIImage(named: "checkedInButton.png"), forState: .Normal)
                }
            }else{
                println("Error in checking in event")
            }
        }
    }
    
    
    @IBAction func onAddEvent(sender: AnyObject) {
        
        //show user alert first about the access premission
        
        switch EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent)  {
        case EKAuthorizationStatus.Authorized:
            println("authorized")
            addEventToCalendar()
        case EKAuthorizationStatus.Denied :
            println("denied")
            UIAlertView(title: "Change Setting Needed", message: "You have denied our calendar access, please update the configuration on your IOS device.", delegate: self, cancelButtonTitle: "OK").show()
        case EKAuthorizationStatus.NotDetermined:
            println("request access")
            requestEventAccess()
            
        default:
            return
        }
    }
    @IBAction func updateRSVP(sender: AnyObject) {
        //first update UI
        self.RSVPstate = !self.RSVPstate!
        showRSVPButton()
        
        //since state changed for UI, here is oposite
        if self.RSVPstate == false {
            unRsvpEvent()
        } else {
            rsvpEvent()
        }
    }
    //MARK: Parse
    func fetchTheEvent (){
        var query = ParseEvent.query()
        query.getObjectInBackgroundWithId(self.eventObjectId ) { (object: PFObject!, error: NSError!) -> Void in
            if object != nil {
                let event = object as ParseEvent 
                self.thisEvent = event
                self.checkedInStatus() //This also refresh tableView
                //self.tableView.reloadData()

            } else {
                println("getting detail event error \(error) ")
            }
        }
    }

    
    func unRsvpEvent() {
        var user = PFUser.currentUser()
        var relation = user.relationForKey("rsvped")
        var events = ParseEvent.query() as PFQuery
        events.getObjectInBackgroundWithId(self.eventObjectId ) { (object: PFObject!, error: NSError!) -> Void in
            if object != nil {
                relation.removeObject(object)
                user.saveEventually()
                self.removeEventFromCalendar()
            } else {
                println("rsvp event error \(error)")
            }
        }
    }
    
    
    func rsvpEvent(){
        var user = PFUser.currentUser()
        var relation = user.relationForKey("rsvped")
        var events = ParseEvent.query() as PFQuery
        events.getObjectInBackgroundWithId(self.eventObjectId ) { (object: PFObject!, error: NSError!) -> Void in
            if object != nil {
                relation.addObject(object)
                user.saveEventually()
            } else {
                println("rsvp event error \(error)")
            }
        }
    }
    
    //MARK : UI update
    //This function only change the look of the RSVPButton, it does not immediately update RSVP info on Parse
    // We do that when user dismiss this controller, just to save some bandwith
    func showRSVPButton(){
        //println("Changing RSVP from \(RSVPstate) to \(updateState)")
        //for past event, no button to show here
         if self.RSVPstate == nil {
            addToCalendarButton.enabled = false
            self.uiViewrsvpButton.hidden = true
            return
        }
        
        if((self.RSVPstate) == true  ){
             rsvpButton.backgroundColor = cancelColor
            rsvpButton.tintColor = UIColor.blackColor()
            rsvpButton.setTitle("Cancel RSVP", forState: .Normal)
            addToCalendarButton.enabled = true
         }else{
            rsvpButton.backgroundColor = RSVPColor
            rsvpButton.tintColor = UIColor.whiteColor()
            rsvpButton.setTitle("RSVP", forState: .Normal)
            addToCalendarButton.enabled = false
         }
        
    }
    
    //MARK: tableview data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //Current behavior:
        //only "TimeInfo" section contains 2 rows, 1 is Time, 1 is Event info
        if thisEvent == nil {
                return 0
        }else{
            
            if(sectionKey[section] == "TimeInfo"){
                if(self.canCheckIn()){
                    return 4
                }else{
                    return 3
                }
            }else{
                return 1
            }
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //Had to return cell in every conditional block, can't use lazy initialization :(
        
        //Header
        if(indexPath.section == 0){
            var cell = tableView.dequeueReusableCellWithIdentifier("EventHeader") as EventHeaderTableViewCell
            //Pass in cell info
            
            cell.eventTitleLabel.text = thisEvent.EventName
            thisEvent.eventProfileImage?.getDataInBackgroundWithBlock({ (imageData: NSData!, error:NSError!) -> Void in
                if imageData != nil {
                    cell.eventLogoImage.image = UIImage(data: imageData)
                    cell.bgImage.image = cell.eventLogoImage.image
                    var blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Dark))
                    blur.frame = cell.bgImage.frame
                    cell.bgImage.addSubview(blur)
                    cell.backgroundView = cell.bgImage
                    //                    println("Getting new image!")
                }
            })
            return cell
            
        }else if self.checkedInState == true || self.canCheckIn() == true{
            //Add check in button
            switch indexPath.row {
                
            case 0:
                var cell = tableView.dequeueReusableCellWithIdentifier("CheckInCell") as CheckInTableViewCell
                if(self.checkedInState){
                    cell.checkInButton.setImage(UIImage(named: "checkedInButton.png"), forState: .Normal)
                }else{
                    cell.checkInButton.addTarget(self, action: "checkInEvent", forControlEvents: .TouchUpInside)
                }
                self.checkInButton = cell.checkInButton
                return cell
                
            case 1:
                var cell = tableView.dequeueReusableCellWithIdentifier("Time") as EventTimeTableViewCell
                cell.timeLabel.text = "\(self.thisEvent.dateToShow!)"
                return cell
                
            case 2:
                var cell = tableView.dequeueReusableCellWithIdentifier("Description") as EventDescriptionTableViewCell
                cell.descriptionLabel.text = self.thisEvent.eventDetail
                return cell
                
            default:
                tableView.rowHeight = 380
                var cell = tableView.dequeueReusableCellWithIdentifier("Map") as EventMapTableViewCell
                cell.addAnotation(self.thisEvent!)
                return cell
            }
           
        }else{
            //Time
            switch indexPath.row {
                
            case 0:
                var cell = tableView.dequeueReusableCellWithIdentifier("Time") as EventTimeTableViewCell
                cell.timeLabel.text = "\(self.thisEvent.dateToShow!)"
                return cell
                
            case 1:
                var cell = tableView.dequeueReusableCellWithIdentifier("Description") as EventDescriptionTableViewCell
                cell.descriptionLabel.text = self.thisEvent.eventDetail
                return cell
                
            default:
                tableView.rowHeight = 380
                var cell = tableView.dequeueReusableCellWithIdentifier("Map") as EventMapTableViewCell
                cell.addAnotation(self.thisEvent!)
                return cell
            }
        }
        
    }
    
    //MARK: tableview delegate
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0{
          //  println("First header section height is set to 0")
            return 0 //Header
        }else{
            return 20
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionKey.count
    }
    

   //MARK: calendar methods
    func addEventToCalendar(){
        //Add code to save event
         var startDate = self.thisEvent.eventDate?.dateByAddingTimeInterval(-60*60*24)
        var endDate = self.thisEvent.eventDate?.dateByAddingTimeInterval(60*60*24*3)
        var predicate = self.eventStore.predicateForEventsWithStartDate(startDate, endDate: endDate, calendars: nil)
        var eV = self.eventStore.eventsMatchingPredicate(predicate) as [EKEvent]!
        
        if eV != nil{
            for i in eV{
                 if i.title == self.thisEvent.EventName{
                   // println("Already have the event!")
                    UIAlertView(title: "Duplicate events found", message: "You already have a same event on your calendar. ", delegate: self, cancelButtonTitle: "Ok").show()
                    return
                }
            }
        }
            println("no duplicaetd found. add event on to calendar")
            var event = EKEvent(eventStore: self.eventStore)
            event.title = self.thisEvent.EventName
            event.startDate = self.thisEvent.eventDate
            event.endDate = self.thisEvent.eventDate
            event.notes = "\(self.thisEvent.eventDetail!)"
            event.calendar = self.eventStore.defaultCalendarForNewEvents
            var result = self.eventStore.saveEvent(event, span: EKSpanThisEvent, error: nil)
            //println("add into calendar : \(result)")
            UIAlertView(title: "Calendar Item added", message: "Your event is added into your calendar on \(self.thisEvent.eventDate!). ", delegate: self, cancelButtonTitle: "OK").show()

    }
    
    //Will automatically remove Event when user unRSVP
    func removeEventFromCalendar(){
        
        var startDate = self.thisEvent.eventDate?.dateByAddingTimeInterval(-60*60*24)
        var endDate = self.thisEvent.eventDate?.dateByAddingTimeInterval(60*60*24*3)
        var predicate = self.eventStore.predicateForEventsWithStartDate(startDate, endDate: endDate, calendars: nil)
        var eV = self.eventStore.eventsMatchingPredicate(predicate) as [EKEvent]!
        
        if eV != nil{
            for i in eV{
                if i.title == self.thisEvent.EventName{
                    // println("Found the event, remove")
                    var result = eventStore.removeEvent(i, span: EKSpanThisEvent, error: nil)
                    println("remove event from calendar: \(result)")
                    
                }
            }
        }else{
            println("cannot find the event to remove")
        }
        
    }

    func requestEventAccess()  {
        
        let alert = UIAlertController(title: "Add this event to calendar?", message: "In order to add this event to your calendar, we may need your permission", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title:"Cancel", style: UIAlertActionStyle.Default, handler:{(alert: UIAlertAction!)-> Void in
            println("Cancel the add event action, do nothing")
       
        }))
        
        alert.addAction(UIAlertAction(title:"Add", style: UIAlertActionStyle.Default, handler:{(alert: UIAlertAction!)-> Void in
            
            self.eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion: {
                granted, error in
                if(granted) && (error == nil){
                    
                    println("Access to Calendar/Reminder granted")
                    self.addEventToCalendar()
                    
                } else {
                    println("access request denied!")
                }
            })
        }))
         self.presentViewController(alert, animated: true, completion: nil)
    }

}


 