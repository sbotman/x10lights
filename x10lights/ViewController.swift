//
//  ViewController.swift
//  x10lights
//
//  Created by Sander Botman on 12/9/15.
//  Copyright © 2015 Botman Inc. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, NSFetchedResultsControllerDelegate {

    var managedObjectContext: NSManagedObjectContext? = nil
    let DEVICE_URL = "http://10.0.1.190:8080/device"
    let ACTION_URL = "http://10.0.1.190:8080/action"
    
    // OUTLETS
    @IBOutlet weak var deviceTableView: UITableView!
    
    @IBOutlet weak var barButtonBright: UIBarButtonItem!
    
    @IBOutlet weak var barButtonDim: UIBarButtonItem!
    
    @IBOutlet weak var barButtonOn: UIBarButtonItem!
    
    @IBOutlet weak var barButtonOff: UIBarButtonItem!
    
    
    // ACTIONS
    @IBAction func barButtonOff(sender: AnyObject) {
        deselectItemsOnTableWithAction("off")
        updateButtonStatus()
    }

    @IBAction func barButtonOn(sender: AnyObject) {
        deselectItemsOnTableWithAction("on")
        updateButtonStatus()
    }
    
    @IBAction func barButtonRefresh(sender: AnyObject) {
        deselectItemsOnTable()
        fetchDeviceList(DEVICE_URL)
        updateButtonStatus()
    }

    @IBAction func barButtonDim(sender: AnyObject) {
        selectItemsOnTableWithAction("dim")
    }
    
    @IBAction func barButtonBright(sender: AnyObject) {
        selectItemsOnTableWithAction("bright")
    }
    
    
    func selectItemsOnTableWithAction(action: String) {
        if let indexPaths = deviceTableView.indexPathsForSelectedRows {
            for var i = 0; i < indexPaths.count; ++i {
                let thisPath = indexPaths[i] as NSIndexPath
                let cell = deviceTableView.cellForRowAtIndexPath(thisPath)
                if let cell = cell {
                    postAction(action, code: cell.accessibilityHint!)
                }
            }
        }
    }
    
    func deselectItemsOnTableWithAction(action: String) {
        if let indexPaths = deviceTableView.indexPathsForSelectedRows {
            for var i = 0; i < indexPaths.count; ++i {
                let thisPath = indexPaths[i] as NSIndexPath
                let cell = deviceTableView.cellForRowAtIndexPath(thisPath)
                if let cell = cell {
                    deviceTableView.deselectRowAtIndexPath(thisPath, animated: true)
                    cell.accessoryType = UITableViewCellAccessoryType(rawValue: 0)!
                    postAction(action, code: cell.accessibilityHint!)
                }
            }
        }
    }

    func deselectItemsOnTable() {
        if let indexPaths = deviceTableView.indexPathsForSelectedRows {
            for var i = 0; i < indexPaths.count; ++i {
                let thisPath = indexPaths[i] as NSIndexPath
                let cell = deviceTableView.cellForRowAtIndexPath(thisPath)
                if let cell = cell {
                    deviceTableView.deselectRowAtIndexPath(thisPath, animated: true)
                    cell.accessoryType = UITableViewCellAccessoryType(rawValue: 0)!
                }
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.deviceTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.deviceTableView.allowsMultipleSelection = true
        // Do any additional setup after loading the view, typically from a nib.
        fetchDeviceList(DEVICE_URL)
        updateButtonStatus()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func fetchDeviceList(device_url: String) {
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedObjectContext = appDelegate.managedObjectContext
        let url = NSURL(string: device_url)!
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
            
            if let urlContent = data {
                do {
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(urlContent, options: NSJSONReadingOptions.MutableContainers)
                    if jsonResult.count > 0 {
                        if let items = jsonResult as? NSArray {
                            self.clearAllItemsFromDatabase("X10Devices")
                            self.addItemsToDatabase("X10Devices", items: items)
                        }
                    }
                } catch {
                    print("JSON serialization failed")
                }
            }
        }
        task.resume()
    }
    

    func postAction(state: String, code: String) {
        let request = NSMutableURLRequest(URL: NSURL(string: ACTION_URL)!)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonString = "{\"state\":\"\(state)\",\"code\":\"\(code)\"}"
        request.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                print("error=\(error)")
                return
            }
            
        }
        task.resume()
    }

    
    
    func addItemsToDatabase(entityName: String, items: NSArray) {
        for item in items {
            let newDevice: NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("X10Devices", inManagedObjectContext: self.managedObjectContext!)
            if let title = item["title"] as? String { newDevice.setValue(title, forKey: "title") }
            if let room = item["room"] as? String { newDevice.setValue(room, forKey: "room") }
            if let code = item["code"] as? String { newDevice.setValue(code, forKey: "code") }
            if let id = item["id"] as? Int { newDevice.setValue(id, forKey: "id") }
            
        }
    }
    
    func clearAllItemsFromDatabase(entityName: String) {
        let request = NSFetchRequest(entityName: entityName)
        request.returnsObjectsAsFaults = false
        do {
            let results = try self.managedObjectContext!.executeFetchRequest(request)
            if results.count > 0 {
                for result in results {
                    self.managedObjectContext!.deleteObject(result as! NSManagedObject)
                    do { try self.managedObjectContext!.save() } catch {}
                }
            }
        } catch {

        }
    }
    
    func insertNewObject(sender: AnyObject) {
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context)
        
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        newManagedObject.setValue(NSString(), forKey: "title")
        
        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
    }
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //if segue.identifier == "showDetail" {
            // if let indexPath = self.deviceTableView.indexPathForSelectedRow {
                
                // let object = self.fetchedResultsController.objectAtIndexPath(indexPath)
                // let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                //controller.detailItem = object
                //controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                //controller.navigationItem.leftItemsSupplementBackButton = true
           // }
       // }
    }
    
    // MARK: - Table View
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    /*
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
            
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                //print("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }
    */
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath)
        cell.textLabel!.text = object.valueForKey("title")!.description
        cell.accessibilityHint = object.valueForKey("code")!.description
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("X10Devices", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.deviceTableView.beginUpdates()
    }
    
    
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        // let selectedCell = deviceTableView.cellForRowAtIndexPath(indexPath)
        // selectedCell?.accessoryType = UITableViewCellAccessoryType(rawValue: 0)!
        updateButtonStatus()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // let selectedCell = deviceTableView.cellForRowAtIndexPath(indexPath)
        // selectedCell?.accessoryType = UITableViewCellAccessoryType(rawValue: 3)!
        updateButtonStatus()
    }
    
    func updateButtonStatus() {
        if let indexPaths = deviceTableView.indexPathsForSelectedRows {
            self.barButtonOn.enabled = true
            self.barButtonOff.enabled = true
            if indexPaths.count > 1 {
                self.barButtonBright.enabled = false
                self.barButtonDim.enabled = false
            } else {
                self.barButtonBright.enabled = true
                self.barButtonDim.enabled = true
            }
        } else {
            self.barButtonOn.enabled = false
            self.barButtonOff.enabled = false
            self.barButtonDim.enabled = false
            self.barButtonBright.enabled = false
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.deviceTableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.deviceTableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            deviceTableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            deviceTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            self.configureCell(deviceTableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
        case .Move:
            deviceTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            deviceTableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }

    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        deviceTableView.endUpdates()
    }

    /*
    // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
    // In the simplest, most efficient, case, reload the table view.
        deviceTableView.reloadData()
    }
    */
    
}

