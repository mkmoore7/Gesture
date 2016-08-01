//
//  ViewController.swift
//  Myo
//
//  Created by Meredith Moore 7/20/16
//  Copyright © 2016 Meredith Moore. All rights reserved.
//

import UIKit

private var myoList: [TLMMyo]{
    return (TLMHub.sharedHub().myoDevices() as? [TLMMyo])!
}

class ViewController: UIViewController {
    
    var data = [[Float]]()
    var recording = false
    var emgNdx = 0, ndx = 0, ndx1 = 0, ndx2 = 0
    var numMyos = 0
    var gestureLength = 3.0
    var mod = 0
    var gestureID = 0
    var gesture: String = ""
    
    //OUTLETS:
    @IBOutlet weak var accel: UILabel!
    @IBOutlet weak var gyro: UILabel!
    @IBOutlet weak var orient: UILabel!
    @IBOutlet weak var emgLabel: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var numMyoLabel: UILabel!

    
    //ACTIONS:
    @IBAction func record(sender: AnyObject) {
        
        _ = NSTimer.scheduledTimerWithTimeInterval(gestureLength, target: self, selector: #selector(ViewController.stopRecording), userInfo: nil, repeats: false)
        recording = true
        print("Timer Started")
        status.text = "recording..."
        
    }
    
    @IBAction func Connect(sender: AnyObject) {
        let controller = TLMSettingsViewController.settingsInNavigationController()
        presentViewController(controller, animated: true, completion: nil)
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initialize()
        setupNotifications()
        
    }
    
    func initialize(){
        //set the connection allowance
        TLMHub.sharedHub().myoConnectionAllowance = 2
        
        //inialize the data matrix, 17x310 right now.
        self.data = [[Float]](count:17, repeatedValue:[Float](count:310, repeatedValue:-1.0))
    }

    func stopRecording(){
        recording = false
        print("Recording Finished")
        status.text = "finished recording"
        emgLabel.text = " "
        orient.text = " "
        gyro.text = " "
        accel.text = " "
        
        //print out the data matrix:
        saveGesture()
        print(gesture)
        
        

        
        //reset the ndx 
        ndx = 0
        ndx1 = 0
        ndx2 = 0
        emgNdx = 0
        gestureID += 1
        
    }
    func saveGesture(){
        gesture = ""
        var xAcc = "", yAcc = "", zAcc = "", xGyro = "", yGyro = "", zGyro = "", pitch = "", yaw = "", roll = "", emg0 = "", emg1 = "", emg2 = "", emg3 = "", emg4 = "", emg5 = "", emg6 = "", emg7 = ""

        for x in 0...300 {
            xAcc += " \(data[0][x]),"
            yAcc += " \(data[1][x]),"
            zAcc += " \(data[2][x]),"
            xGyro += " \(data[3][x]),"
            yGyro += " \(data[4][x]),"
            zGyro += " \(data[5][x]),"
            pitch += " \(data[6][x]),"
            yaw += " \(data[7][x]),"
            roll += " \(data[8][x]),"
            emg0 += " \(data[9][x]),"
            emg1 += " \(data[10][x]),"
            emg2 += " \(data[11][x]),"
            emg3 += " \(data[12][x]),"
            emg4 += " \(data[9][x]),"
            emg5 += " \(data[10][x]),"
            emg6 += " \(data[11][x]),"
            emg7 += " \(data[12][x]),"
            
        }
        gesture = "**Gesture ID: \(gestureID) \n Acceleration: \n x: \(xAcc) \n y: \(yAcc) \n z: \(zAcc) \n Gyroscope: \n x: \(xGyro) \n y: \(yGyro) \n z: \(zGyro) \n Orientation: \n Pitch: \(pitch) \n Yaw: \(yaw) \n Roll: \(roll) \n EMG: \n pod0: \(emg0) \n pod1: \(emg1) \n pod2: \(emg2) \n pod3: \(emg3) \n pod4: \(emg4) \n pod5: \(emg5) \n pod6: \(emg6) \n pod7: \(emg7)"
        
        //now save the gesture to Firebase as a new gesture
        

//        //save the gesture
//        let filename = getDocumentsDirectory().stringByAppendingPathComponent("gestureData.txt")
//        print(filename)
//        
//        do {
//            try gesture.writeToFile(filename, atomically: true, encoding: NSUTF8StringEncoding)
//        } catch {
//            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
//        }
    }
    
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func preprocess(){
        transform()
        print(data)
        normalize()
        print(data)
    }
    func normalize(){
        print("Normalizing..")
        
        
    }
    
    func transform(){
        print("Transforming...")
        for x in 0...150{
            for y in 0...16{
                data[y][x] -= data[y][0]
            }
        }
    }
    
    func setupNotifications(){
        let notifier = NSNotificationCenter.defaultCenter()
        notifier.addObserverForName(TLMHubDidConnectDeviceNotification, object: nil, queue: nil) {
            (notification: NSNotification!) -> Void in
            for x in myoList {
                x.setStreamEmg(.Enabled)
            }
        }
        
        notifier.addObserver(
            self,
            selector: #selector(ViewController.didConnectDevice(_:)),
            name: TLMHubDidConnectDeviceNotification,
            object: nil)
        notifier.addObserver(
            self,
            selector: #selector(ViewController.didDisconnectDevice(_:)),
            name: TLMHubDidDisconnectDeviceNotification,
            object: nil)
        notifier.addObserver(
            self,
            selector: #selector(ViewController.didRecieveAccelerationEvent(_:)),
            name: TLMMyoDidReceiveAccelerometerEventNotification,
            object: nil)
        notifier.addObserver(
            self,
            selector: #selector(ViewController.onEmg(_:)),
            name: TLMMyoDidReceiveEmgEventNotification,
            object: nil)
        notifier.addObserver(
            self,
            selector:#selector(ViewController.didReceiveOrientationEvent(_:)),
            name: TLMMyoDidReceiveOrientationEventNotification,
            object: nil)
        
        notifier.addObserver(
            self,
            selector:#selector(ViewController.didReceiveGyroscopeEvent(_:)),
            name: TLMMyoDidReceiveGyroscopeEventNotification,
            object: nil)

    }
    
    func didConnectDevice(notification: NSNotification) {
        status.text = "Status: Connected!"
        numMyos += 1
        numMyoLabel.text = "Number of Myos Connected: \(numMyos)"
        print("MyoDevices size: \(TLMHub.sharedHub().myoDevices().count)")
        print("NumMyos: \(numMyos)")
        
    }
    func didDisconnectDevice(notification: NSNotification) {
        status.text = "Status: Disconnected :("
        numMyos -= 1
        numMyoLabel.text = "Number of Myos Connected: \(numMyos)"
    }


    func didRecieveAccelerationEvent(notification: NSNotification) {
        let eventData = notification.userInfo as! Dictionary<NSString, TLMAccelerometerEvent>
        let accelerometerEvent = eventData[kTLMKeyAccelerometerEvent]!
        
        let acceleration = accelerometerEvent.vector;
        let x = acceleration.x
        let y = acceleration.y
        let z = acceleration.z
        
        accel.text = "Accel: x(\(x)), y(\(y)), z(\(z))"
        if(recording){
            data[0][ndx] = x
            data[1][ndx] = y
            data[2][ndx] = z
            ndx += 1
        }

        
    }
    func didReceiveGyroscopeEvent(notification:NSNotification){
        let eventData = notification.userInfo as! Dictionary<NSString, TLMGyroscopeEvent>
        let gyroscopeEvent = eventData[kTLMKeyGyroscopeEvent]!
        
        let gyroData = gyroscopeEvent.vector;
        let x = gyroData.x
        let y = gyroData.y
        let z = gyroData.z
        gyro.text = "Gryo: x(\(x)), y(\(y)), z(\(z))"
        
        if(recording){
            data[3][ndx1] = x
            data[4][ndx1] = y
            data[5][ndx1] = z
            ndx1 += 1
        }

        
    }
    func didReceiveOrientationEvent(notification:NSNotification){
        let eventData = notification.userInfo as! Dictionary<NSString, TLMOrientationEvent>
        let orientationEvent = eventData[kTLMKeyOrientationEvent]
        
        let angles = GLKitPolyfill.getOrientation(orientationEvent)
        let pitch = CGFloat(angles.pitch.radians)
        let yaw = CGFloat(angles.yaw.radians)
        let roll = CGFloat(angles.roll.radians)

        orient.text = "Orientation: pitch(\(pitch)), yaw(\(yaw)), roll(\(roll))"
        
        if(recording){
            data[6][ndx2] = Float(pitch)
            data[7][ndx2] = Float(yaw)
            data[8][ndx2] = Float(roll)
            ndx2 += 1
        }
        
    }
    
    func onEmg(notification: NSNotification) {
        if let emgEvent = notification.userInfo?[kTLMKeyEMGEvent] as? TLMEmgEvent {
            //print(emgEvent.rawData)
            emgLabel.text = "\(emgEvent.rawData)"
            
            let pod0 = emgEvent.rawData[0]
            let pod1 = emgEvent.rawData[1]
            let pod2 = emgEvent.rawData[2]
            let pod3 = emgEvent.rawData[3]
            let pod4 = emgEvent.rawData[4]
            let pod5 = emgEvent.rawData[5]
            let pod6 = emgEvent.rawData[6]
            let pod7 = emgEvent.rawData[7]
            
            
            if(recording){
                if(mod % 4 == 0){
                    data[9][emgNdx] = Float(pod0 as! NSNumber)
                    data[10][emgNdx] = Float(pod1 as! NSNumber)
                    data[11][emgNdx] = Float(pod2 as! NSNumber)
                    data[12][emgNdx] = Float(pod3 as! NSNumber)
                    data[13][emgNdx] = Float(pod4 as! NSNumber)
                    data[14][emgNdx] = Float(pod5 as! NSNumber)
                    data[15][emgNdx] = Float(pod6 as! NSNumber)
                    data[16][emgNdx] = Float(pod7 as! NSNumber)
                    emgNdx += 1
                }
                mod += 1
            }
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

