

import AVFoundation
import UIKit

enum CameraError: String {
    case invalidDeviceInput     = "Something is wrong with the camera. We are unable to capture the input"
    case invalidScannedValue    = "This value scanned is not valid. This app scans EAN-8 and EAN-13"
}

// Barcode Scanner View Controller

// IN TERMS OF UIKIT CONFORMING TO SWIFTUI
// The way UIKit communicates to SwiftUI is through delegates and protocols
// UIKit talks to Coordinator -> Coordinator talks to SwiftUI

// FOR FUNC didFind INSIDE OF PROTOCOL
// when you find the barcode, send it to your delegate -> our delegate is going to be our coordinator -> coordinator takes that barcode and will send it up to our SwiftUI view


protocol ScannerVCDelegate: AnyObject {
    func didFind(barcode: String)          // method that fires off when we successfully find a barcode (passed at the bottom)
    func didSurface(error: CameraError)    // method that fires off when we get an error  (passed around frequently)

}

final class ScannerVC: UIViewController {
    let captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    weak var scannerDelegate: ScannerVCDelegate!
    
    init(scannerDelegate: ScannerVCDelegate) {
        super.init(nibName: nil, bundle: nil)
        self.scannerDelegate = scannerDelegate
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented")}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let previewLayer = previewLayer else {
            scannerDelegate?.didSurface(error: .invalidDeviceInput)
            return
        }
        
        previewLayer.frame = view.layer.bounds
    }
    
    
    private func setupCaptureSession() {             // do all of the setup to get the camera running and looking for barcodes
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {              // do we have have a device that can capture video
            scannerDelegate.didSurface(error: .invalidDeviceInput)
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            try videoInput = AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            scannerDelegate.didSurface(error: .invalidDeviceInput)
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)                 // alot of this code is just checks to make sure you can use the camera
        } else {
            scannerDelegate.didSurface(error: .invalidDeviceInput)
            return
        }
        
        let metaDataOutput = AVCaptureMetadataOutput()                         // This is what actually gets scanned
         
        if captureSession.canAddOutput(metaDataOutput) {
            captureSession.addOutput(metaDataOutput)
            metaDataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metaDataOutput.metadataObjectTypes = [.ean8, .ean13]             // standard 8 or 13 digit barcode
        }else {
            scannerDelegate.didSurface(error: .invalidDeviceInput)
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer!.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
        
        captureSession.startRunning()
    }
}

extension ScannerVC: AVCaptureMetadataOutputObjectsDelegate {    //what do we do when we scan the barcode?
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first else {       // do we have a metadata object in our array above? cool, grab that.
            scannerDelegate?.didSurface(error: .invalidScannedValue)
            return
        }
        
        guard let machineReadableObject = object as? AVMetadataMachineReadableCodeObject else {     // is it machine readable? cool.
            scannerDelegate?.didSurface(error: .invalidScannedValue)

            return
        }
        
        guard let barcode = machineReadableObject.stringValue else {        // lets take that machine readable and get the string value
            scannerDelegate?.didSurface(error: .invalidScannedValue)
            return
        }
        
        scannerDelegate?.didFind(barcode: barcode)      // that string value we mentioned above, lets send it to our delegate
        
    }
    
}





// What we need to setup now is someone to listen to our view controller that is yelling out all of this informarion.
// That is going to be our coordinator. The coordinator is the middle man/translator for the ViewController to the SwiftUI View
