//
//  ViewController.swift
//  FaceRecognition
//
//  Created by mdc on 2016-03-10.
//  Copyright © 2016 BMO. All rights reserved.
//

import UIKit
import AVFoundation
import QuartzCore
import CoreGraphics

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var indexForFaceID: Dictionary<Int, AnyObject> = Dictionary()
    var avfFaceLayers: Dictionary<Int, CALayer> = Dictionary()
    
    struct DegreesToRadians {
        func convert(degrees:CGFloat) ->CGFloat{
            return CGFloat(Double(degrees) * M_PI / Double(180))
        }
    }

    
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    
    // Added to support different barcodes
    //    let supportedBarCodes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeUPCECode, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeAztecCode]
    let supportedBarCodes = [AVMetadataObjectTypeFace]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadDevice()
        
    }
    
    func loadDevice(){
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
        // as the media type parameter.

        let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        
        for availabeDevice in availableCameraDevices {
            if availabeDevice.position == .Front {
                let captureDevice = availabeDevice as! AVCaptureDevice
                loadLayerWithDevice(captureDevice)
            }
        }
    }
    
    func loadLayerWithDevice(captureDevice: AVCaptureDevice){
        
        if captureDevice.isFocusModeSupported(.ContinuousAutoFocus) {
            try! captureDevice.lockForConfiguration()
            captureDevice.focusMode = .ContinuousAutoFocus
            captureDevice.videoZoomFactor = 1
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            
            // Detect all the supported bar code
            captureMetadataOutput.metadataObjectTypes = supportedBarCodes
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture
            captureSession?.startRunning()
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        let faceObjects = metadataObjects as? [AVMetadataFaceObject]
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if faceObjects == nil || faceObjects!.count == 0 {
            for faceId in avfFaceLayers.keys {
                let layer = avfFaceLayers[faceId]
                layer?.removeFromSuperlayer()
                avfFaceLayers.removeValueForKey(faceId)
                indexForFaceID.removeValueForKey(faceId)
            }
            print("No Fcae detected")
            return
        }
        
        if ((videoPreviewLayer?.connection.enabled) == nil) {
            return
        }
        
        var unseen = Set(avfFaceLayers.keys)
        
        for face in faceObjects! {
            unseen.remove(face.faceID)
            
            var layer = avfFaceLayers[face.faceID]
            
            if layer == nil {
                layer = CALayer()
//                layer?.borderColor = UIColor.greenColor().CGColor
//                layer?.borderWidth = 5.0
                self.videoPreviewLayer?.addSublayer(layer!)
                avfFaceLayers[face.faceID] = layer
            }
            
            let adjustedFaceObject = self.videoPreviewLayer?.transformedMetadataObjectForMetadataObject(face) as! AVMetadataFaceObject
            
            var transform = CATransform3DIdentity
            layer?.transform = transform
            layer?.frame = (adjustedFaceObject.bounds)
            
            if adjustedFaceObject.hasRollAngle {
                transform = CATransform3DRotate(transform, DegreesToRadians().convert(adjustedFaceObject.rollAngle), 0, 0, 1)
                layer?.transform = transform
            }
            
            let image = UIImage(named: "silhoute.png")
            
            let cgFace = image?.CGImage
            
            let layers = layer?.sublayers
            if layers == nil {
                layer?.addSublayer(CALayer())
            }
            
            let graphicLayer = layer?.sublayers![0]
            graphicLayer?.contents = cgFace
            
            let SCALE_SUNNY_FACE = 0.9
            
            var frame = layer?.bounds
            let newHeight = (frame?.size.width)! * (image?.size.height)!/(image?.size.width)!
            frame?.size.height = newHeight
            frame?.origin.x += CGFloat(1.0 - SCALE_SUNNY_FACE) * (frame?.size.width)!/2
            frame?.origin.y -= CGFloat(1.0 - SCALE_SUNNY_FACE) * (frame?.size.height)!
            frame?.size.width *= CGFloat(SCALE_SUNNY_FACE)
            frame?.size.height *= CGFloat(SCALE_SUNNY_FACE)
            
            graphicLayer?.frame = frame!

            
            for faceId in unseen {
                layer = avfFaceLayers[faceId]
                layer?.removeFromSuperlayer()
                avfFaceLayers.removeValueForKey(faceId)
                indexForFaceID.removeValueForKey(faceId)
            }
            
//            CATransaction.commit()
            print("faces detected")
            
        }
    }
}

