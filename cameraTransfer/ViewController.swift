//
//  ViewController.swift
//  cameraTransfer
//
//  Created by Takuro TOKUNAGA on 2020/07/23.
//  Copyright © 2020 Takuro TOKUNAGA. All rights reserved.
//

//  Environment:
//  Swift 5.1.3
//  Xcode 11.3.1
//  Modified: July 23, 2020
//  Updated : January 09, 2021

import UIKit
import AVFoundation
//import FirebaseDatabase
import FirebaseStorage

class ViewController: UIViewController {
  
    var captureSession = AVCaptureSession()

    // Upload destination
    var imageReference: StorageReference{
        return Storage.storage().reference().child("images")

    }
    
    //MARK:- Camera & Mike setting
    var mainCamera: AVCaptureDevice?    // Camera generation - iSight camera, frontside
    var innerCamera: AVCaptureDevice?   // Camera generation - Facetime camera, backside
    var currentDevice: AVCaptureDevice? // Camera which is used currently

    // AVCapture device -(AVCaptureDeviceInpt)-> AVCaptureSession
    var photoOutput : AVCapturePhotoOutput? // Firebase upload routine is included
    
    // Layer define
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    // added for timer
    var timer: Timer?    // timer for taking picture
    var timermp3: Timer? // timer for playing mp3
    
    // added for sound play from SoundFirebase
    var player = AVPlayer()
    var soundReference: StorageReference{
        return Storage.storage().reference().child("sounds")
    }
    
    // shutter button
    @IBOutlet weak var cameraButton: UIButton!
    
    @IBOutlet weak var tapButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.removeObject(forKey:"sample")
        
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        captureSession.startRunning()
        styleCaptureButton()
        setupAudioSession() // check headphone or speaker
        URLstartTimer()
    }
    
    // display taken & uploading picture
    @IBOutlet weak var uploadImage: UIImageView!
    
    // download image
    @IBOutlet weak var downloadImage: UIImageView!
    
    // added at the bottom page
    override func didReceiveMemoryWarning(){
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }
        
    // flash & stabilization
    // (_ sender: Any) was modified to (_ sender: Timer)
    @IBAction func cameraButton_TouchUpInside(_ sender: Timer) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto // flash
        settings.isAutoStillImageStabilizationEnabled = true // stabilization
        self.photoOutput?.capturePhoto(with: settings, delegate: self as AVCapturePhotoCaptureDelegate)
    }
    
    // added for interval taking picture
    @IBAction func tapButton(_ sender: UIButton) {
    // Adjust timeInterval for your preference
    // If timeInterval is too short, the shutter sound is generated
    self.timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(ViewController.self.cameraButton_TouchUpInside(_:)), userInfo: nil, repeats: true)
        
    // for mp3
    self.timermp3 = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(ViewController.self.soundplay), userInfo: nil, repeats: true)
    }
       
    // Stop timer and Freeing up of memory
    @IBAction func buttonAction(_ sender: Any) {
        //print("invalidate")
        self.timer?.invalidate()    // for taking picture
        self.timermp3?.invalidate() // for mp3
    }
}

//MARK:- Save images
extension ViewController: AVCapturePhotoCaptureDelegate{
    // added: turn off the shutter sound
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // dispose system shutter sound
        AudioServicesDisposeSystemSoundID(1108)
    }
    
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(){
            
            let uiImage = UIImage(data: imageData) // picture taken by isight
            UIImageWriteToSavedPhotosAlbum(uiImage!, nil, nil, nil)

            //MARK:- Upload images to Firebase
            uploadImage.image = uiImage // added for uploading to Firebase
            
            // for file name
            //let date = Date()
            //let calendar = Calendar.current
            //let year = calendar.component(.year, from: date)
            //let month = calendar.component(.month, from: date)
            //let day = calendar.component(.day, from: date)
            //let hour = calendar.component(.hour, from: date)
            //let minute = calendar.component(.minute, from: date)
            //let second = calendar.component(.second, from: date)
            
            // Upload file name
            // let filename = "isight.jpeg"
            //let filename = "isight_\(year)_\(month)_\(day)_\(hour)_\(minute)_\(second).jpeg"
            //guard let image = uploadImage.image else { return }
            
            // Those two statements are for dummy file statements
            let dfilename = "isight.jpeg"                        // d is for dummy
            let dimg = "analyzed.jpeg"                        // analyzed image by darknet
            guard let dimage = uploadImage.image else { return } // d is for dummy
            
            // transform picture to data
            //guard let imageData = image.jpegData(compressionQuality: 0.0) else { return }
            guard let dimageData = dimage.jpegData(compressionQuality: 0.0) else { return } // this is for dummy file
            
            //let uploadImageRef = imageReference.child(filename)
            let duploadImageRef = imageReference.child(dfilename) // this is for dummy file
                    
            // setting of metadata
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpeg"
                
            //let uploadTask = uploadImageRef.putData(imageData, metadata: metaData) { (metadata,error) in
            //        print("Upload Task Finished")
            //        print(metadata ?? "No Metadata")
            //        print(error ?? "No error")
            //}
            
            //uploadTask.observe(.progress) { (snapshot) in
            //    let completed = Double((snapshot.progress?.completedUnitCount)!)
            //    let total = Double((snapshot.progress?.totalUnitCount)!)
            //    let percentComplete = (completed/total)*100.0
            //    print("progress:",percentComplete,"%")
            //    print(snapshot.progress ?? "No More Progress")
            //}
            
            // This routine is for dummy file: upload task for dummy file from here
            let duploadTask = duploadImageRef.putData(dimageData, metadata: metaData) { (metadata,error) in
                    print("Upload Task Finished")
                    print(metadata ?? "No Metadata")
                    print(error ?? "No error")
            }
            
            // This routine is for dummy file: upload task for dummy file from here
            duploadTask.observe(.progress) { (snapshot) in
                let completed = Double((snapshot.progress?.completedUnitCount)!)
                let total = Double((snapshot.progress?.totalUnitCount)!)
                let percentComplete = (completed/total)*100.0
                print("progress:",percentComplete,"%")
                print(snapshot.progress ?? "No More Progress")
            }
            
            // upload task resume for non-dummy and dummy
            //uploadTask.resume()
            duploadTask.resume() // This is for dummy file
                        
            //MARK:- Download analyzed images from Firebase
            //let downloadImageRef = imageReference.child(dfilename) // this line give show the taken picture at the bottom UIImageView
            let downloadImageRef = imageReference.child(dimg)
            
            // get URL
            downloadImageRef.downloadURL{ url, error in
                if (error != nil){
                    print("error!")
                } else {
                    print("success! URL:",url!)
                }
            }
            
            let downloadTask = downloadImageRef.getData(maxSize: 1024*1024*12) { data,error in
                
                if let data = data {
                    let image = UIImage(data: data)
                    self.downloadImage.image = image
                }
                print(error ?? "No Error")
            }
            
            downloadTask.observe(.progress) { (snapshot) in
                let completed = Double((snapshot.progress?.completedUnitCount)!)
                let total = Double((snapshot.progress?.totalUnitCount)!)
                let percentComplete = (completed/total)*100.0
                print("progress:",percentComplete,"%")
                print(snapshot.progress ?? "No More Progress")
            }
            
            //downloadTask.resume() // gives an error as it is
            downloadTask.observe(.resume) { (snapshot) in
                print("Download is resumed")
            }
        }
    }
}

extension ViewController{
    
    // Camera resolution
    func setupCaptureSession(){
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
           
    // Device setting
    func setupDevice(){
        // Camera property setting
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        
        // Get a camera satisfying the property
        let devices = deviceDiscoverySession.devices
        
        for device in devices{
            if device.position == AVCaptureDevice.Position.back{
                mainCamera = device
            }else if device.position == AVCaptureDevice.Position.front{
                innerCamera = device
            }
        }
        // activated camera = iSight camera
        currentDevice = mainCamera
    }
    
    // MARK:- Camera inputs initialization
    // Setting of inputs & outputs
    func setupInputOutput(){
        do{
            // input initialization
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            // add input into session
            captureSession.addInput(captureDeviceInput)
            // object which receives outputs
            photoOutput = AVCapturePhotoOutput()
            // format setting
            if #available(iOS 11.0, *) {
                photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            } else {
                print("iOS after 11.0 is necessary!")
                // Fallback on earlier versions
            }
            
            captureSession.addOutput(photoOutput!)
        }catch{
            print(error)
        }
    }
    
    // MARK:- Camera view setting, layer & view
    // layer setting
    func setupPreviewLayer(){
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession) // initialization of preview layer with captureSession
        self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        self.cameraPreviewLayer?.frame = view.frame
        self.view.layer.insertSublayer(self.cameraPreviewLayer!,at:0)
    }

    // camera button style
    func styleCaptureButton(){
        cameraButton.layer.borderColor = UIColor.red.cgColor
        cameraButton.layer.borderWidth = 5
        cameraButton.clipsToBounds = true
        cameraButton.layer.cornerRadius = min(cameraButton.frame.width, cameraButton.frame.height) / 2
        cameraButton.layer.backgroundColor = UIColor.red.cgColor
        
        //
        tapButton.layer.borderColor = UIColor.blue.cgColor
        tapButton.layer.borderWidth = 5
        tapButton.clipsToBounds = true
        tapButton.layer.cornerRadius = min(tapButton.frame.width, tapButton.frame.height) / 2
        tapButton.layer.backgroundColor = UIColor.blue.cgColor
    }
}

// for sound play from here
extension ViewController {
    // changed from func to @obj func for Timer.scheduledTimer
    @objc func soundplay() {
        
        // sound file name
        let filename = "up_output.mp3"

        // getDownloadURL
        let downloadRef = soundReference.child(filename)

        // get URL
        downloadRef.downloadURL{ url, error in
            if (error != nil){
                print("error!")
                
            } else {
                let urlString = url!.absoluteString
                //print(type(of: urlString))
                //print("string type URL:",urlString)
                //self.printOut(string: urlString)  // Display Stringed url.
                self.loadURL(radioURL: urlString) // Play url
            }
        }
    }
}

extension ViewController{
    // show string type
    func printOut(string: String) -> String {
        // print(string)
        
        return string
    }
}

extension ViewController{
    // streaming play
    func loadURL(radioURL: String) { // URL with String type
        
        guard let url = URL.init(string: radioURL) else { return } // String -> URL
        let playerItem = AVPlayerItem.init(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // player setting
        player.playImmediately(atRate: 3.0)
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
        self.view.layer.addSublayer(playerLayer)
        
        // call functions with delay
        //player.play()
        player.playImmediately(atRate: 2.0)
    }
    
    // stop play
    func stopPlayer() {
        //player.replaceCurrentItem(with: nil)
        player.replaceCurrentItem(with: nil)
        print("player was stopped")
    }
}
// for sound play until here

// new sound play routine from here
extension ViewController {
    func URLstartTimer() {
        if timermp3 == nil {
            timermp3 =  Timer.scheduledTimer(
                timeInterval: TimeInterval(1.0),
                target      : self,
                selector    : #selector(ViewController.urlupdatechecker),
                userInfo    : nil,
                repeats     : true
            )
        }
    }
    
    func stopTimer() {
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }
}

extension ViewController {
    // you can copy and paste all the below statements to override func viewDidload
    // by removing the soundplay() in the override func
    
    @objc func urlupdatechecker() { // originally witten as 'func soundplay() {' for timer schedule. @objc is added for Timer.scheduledTimer
        
        // sound file name
        let filename = "up_output.mp3"

        // getDownloadURL
        let downloadRef = soundReference.child(filename)
        //print(downloadRef)
        
        var currenturl = String()
        let userDefaults = UserDefaults.standard
        
        // get URL
        downloadRef.downloadURL{ url, error in
            if (error != nil){
                print("error!")
                
            } else {
                let urlString = url!.absoluteString
                //print("what is the urlString?")
                //print("string type URL:",urlString)
                //self.printOut(string: urlString)  // Display Stringed url.
                
                switch urlString {
                case userDefaults.string(forKey: "sample"): // urlString == userDefaults.string
                    print("Same MP3, stay.")
                    
                default: // urlString not equals to userDefaults.string
                    self.stopPlayer()
                    print("New MP3, play!")
                    self.loadURL(radioURL: urlString) // Play url
                    userDefaults.set(urlString, forKey: "sample")
                }
                
                // show current url
                currenturl = self.printOut(string: urlString)
                print(currenturl)
                
                //if urlString != userDefaults.string(forKey: "sample") {
                //    self.loadURL(radioURL: urlString) // Play url
                //    print("New MP3, play!")
                //    userDefaults.set(urlString, forKey: "sample")
        
                //} else if urlString == userDefaults.string(forKey: "sample") {
                //    print("Same MP3, stop.")
                //    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { // Change `2.0` to the desired number of seconds.
                        // Code you want to be delayed
                        //self.stopPlayer()
                //        currenturl = self.printOut(string: urlString)
                //        print(currenturl)
                //    }
                //}
            }
            //Add your implementation here
            //print("unplayed MP3 found.")
            //self.streaming(radioURL: urlString) // Play url
            //self.stopPlayer() // stop
        }
    }
}
// new sound play routine untile here

// check the existance of headphone
// description by Swift 4.2:
extension ViewController{
    @objc func handleRouteChange(_ notification: Notification) {
        let reasonValue = (notification as NSNotification).userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt
        let routeDescription = (notification as NSNotification).userInfo![AVAudioSessionRouteChangePreviousRouteKey] as! AVAudioSessionRouteDescription?

        NSLog("Route change:")
        if let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) {
            switch reason {
            case .newDeviceAvailable:
                NSLog("     NewDeviceAvailable")
            case .oldDeviceUnavailable:
                NSLog("     OldDeviceUnavailable")
            case .categoryChange:
                NSLog("     CategoryChange")
                NSLog(" New Category: %@", AVAudioSession.sharedInstance().category.rawValue)
            case .override:
                NSLog("     Override")
            case .wakeFromSleep:
                NSLog("     WakeFromSleep")
            case .noSuitableRouteForCategory:
                NSLog("     NoSuitableRouteForCategory")
            case .routeConfigurationChange:
                NSLog("     RouteConfigurationChange")
            case .unknown:
                NSLog("     Unknown")
            @unknown default:
                NSLog("     UnknownDefault(%zu)", reasonValue)
            }
        } else {
            NSLog("     ReasonUnknown(%zu)", reasonValue)
        }

        if let prevRout = routeDescription {
            NSLog("Previous route:\n")
            NSLog("%@", prevRout)
            NSLog("Current route:\n")
            NSLog("%@\n", AVAudioSession.sharedInstance().currentRoute)
        }
    }
}

extension ViewController{
    private func setupAudioSession() {
        // Configure the audio session
        let sessionInstance = AVAudioSession.sharedInstance()

        // we don't do anything special in the route change notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleRouteChange(_:)),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: sessionInstance)
        
        // change the output route headphone <-> speaker
        do {
            try sessionInstance.setCategory(AVAudioSession.Category.playAndRecord, mode: .spokenAudio, options:.defaultToSpeaker)
            try sessionInstance.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("error.")
        }
    }
}
