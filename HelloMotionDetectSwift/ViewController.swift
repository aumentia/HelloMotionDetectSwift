//
//  ViewController.swift
//  HelloMotionDetectSwift
//
//  Created by Pablo GM on 02/09/15.
//  Copyright (c) 2015 Aumentia Technologies SL. All rights reserved.
//

import UIKit


class ViewController: UIViewController, vsMotionProtocol, CameraCaptureDelegate
{
    var _aumMotion:vsMotion!
    var _captureManager:CaptureSessionManager!
    var _cameraView:UIView!
    var _alertController:UIAlertController!
    
    
    // MARK: - View Life Cycle
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        let myLogo:UIImage          = UIImage(named: "aumentia®.png")!
        let myLogoView:UIImageView  = UIImageView(image: myLogo)
        myLogoView.frame            = CGRect(x: 0, y: 0, width: 150, height: 61)
        self.view.addSubview(myLogoView)
        self.view.bringSubview(toFront: myLogoView)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        initCapture()
        
        addMotionDetect()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        removeCapture()
        
        removeMotionDetect()
    }

    
    // MARK: - Memory Management
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - AumMotion Life Cycle

    func addMotionDetect()
    {
        if ( _aumMotion == nil )
        {
            // Init
            _aumMotion = vsMotion(key: "10ca4de26ff576c5d2edf490a8622eca3da4d600", setDebug: true)
            
            assert(_aumMotion != nil, "Check your API KEY")
            
            // Set delegate
            _aumMotion.vsMotionDelegate = self
            
            // Add motion filter
            _aumMotion.initMotionDetection(withThreshold: 3, enableDebugLog: false)
            
            // Set the period the buttons will be inactive once one is clicked
            _aumMotion.setInactivePeriod(NSNumber(value:vsMotionDelay.LOWDELAY.rawValue))
            
            // Add ROIs
            let ROI1 = CGRect(origin: CGPoint(x: 5, y: 5), size: CGSize(width: 20, height: 20))
            _aumMotion.addButton(with: ROI1)
            
            let ROI2 = CGRect(origin: CGPoint(x: 80, y: 80), size: CGSize(width: 15, height: 15))
            _aumMotion.addButton(with: ROI2)
            
            // Draw ROIs
            addRectToView(rect: ROI1)
            addRectToView(rect: ROI2)
        }
    }
    
    func removeMotionDetect()
    {
        if ( _aumMotion != nil )
        {
            _aumMotion.removeDetection()
            
            _aumMotion.clearButtons()
            
            _aumMotion.vsMotionDelegate = nil
            _aumMotion                  = nil
        }
    }
    
    
    // MARK: - Camera management
    
    func initCapture()
    {
        // Init capture manager
        _captureManager = CaptureSessionManager()
        
        // Set delegate
        _captureManager.delegate = self
        
        // Set video streaming quality
        _captureManager.captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        _captureManager.outPutSetting = NSNumber(value: kCVPixelFormatType_32BGRA)
        
        _captureManager.addVideoInput(AVCaptureDevicePosition.front)
        _captureManager.addVideoOutput()
        _captureManager.addVideoPreviewLayer()
        
        let layerRect:CGRect = self.view.bounds
        
        _captureManager.previewLayer.isOpaque = false
        _captureManager.previewLayer.bounds = layerRect
        
        _captureManager.previewLayer.position = CGPoint(x: layerRect.midX, y: layerRect.midY)
        
        // Create a view where we attach the AV Preview Layer
        _cameraView = UIView(frame: self.view.bounds)
        _cameraView.layer .addSublayer(_captureManager.previewLayer)
        
        // Add the view we just created as a subview to the View Controller's view
        self.view.addSubview(_cameraView)
        
        // Start
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            
            self.startCaptureManager()
        }
    }
    
    func removeCapture()
    {
        _captureManager.captureSession.stopRunning()
        _cameraView.removeFromSuperview()
        _captureManager = nil
        _cameraView     = nil
    }
    
    func startCaptureManager()
    {
        autoreleasepool
        {
            _captureManager.captureSession.startRunning()
        }
    }
    
    func processNewCameraFrameRGB(_ cameraFrame: CVImageBuffer!) {
        
        _aumMotion.processRGBFrame(cameraFrame, saveImageToPhotoAlbum: false)
    }
    
    func processNewCameraFrameYUV(_ cameraFrame: CVImageBuffer!) {
        
        _aumMotion.processYUVFrame(cameraFrame, saveImageToPhotoAlbum: false)
    }
    
    
    // MARK: - Delegates
    
    func buttonClicked(_ buttonId: NSNumber!) {
        
        print("Clicked button \(buttonId.intValue)")
        
        alert(message: "Button \(buttonId.intValue) clicked!")
    }
    
    func buttonsActive(_ isActive: Bool) {
        
        if ( !isActive )
        {
            print("Buttons disabled")
        }
    }

    
    // MARK: - Utils
    
    func addRectToView(rect: CGRect)
    {
        let result:CGSize   = UIScreen.main.bounds.size
        
        let rect:CGRect     = CGRect(x: rect.origin.x / 100.0 * result.width,
                                     y: rect.origin.y / 100.0 * result.height,
                                     width: rect.size.width / 100.0 * result.width,
                                     height: rect.size.height / 100.0 * result.height)
        
        let frameView:UIView        = UIView(frame: rect)
        frameView.backgroundColor   = UIColor.clear
        frameView.layer.borderColor = UIColor(red: 0.0/255.0, green: 158.0/255.0, blue: 224.0/255.0, alpha: 1.0).cgColor
        frameView.layer.borderWidth = 3.0
        self.view.addSubview(frameView)
    }
    
    func alert(message: String)
    {
        DispatchQueue.main.async {
            
            if ( self._alertController != nil )
            {
                self._alertController.dismiss(animated: true, completion:nil)
                self._alertController = nil
            }
            
            self._alertController = UIAlertController(title: "Aumentia", message: message, preferredStyle: .alert)
            
            let OKAction = UIAlertAction(title: "Ok", style: .default) { (action) in
                self._alertController.dismiss(animated: true, completion:nil)
            }
            self._alertController.addAction(OKAction)
            
            self.present(self._alertController, animated: true, completion: nil)
        }
    }
}

