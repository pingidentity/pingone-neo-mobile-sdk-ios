//
//  QRScannerViewController.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import AVFoundation

public class QRScannerViewController: UIViewController, BaseViewController {
    
    var viewModel: QRScannerViewModel!
    public var walletCoordinator: WalletCoordinator!
    
    public func setViewModel<VM>(_ viewModel: VM) where VM : BaseViewModel {
        self.viewModel = (viewModel as! QRScannerViewModel)
    }
    
    @IBOutlet weak var cameraView: UIView!
    
    var overlayView: UIView!
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
        
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.overrideUserInterfaceStyle = .light

        self.cameraView.backgroundColor = UIColor.black
        self.addOverlayView()
        self.startCaptureSession()
    }
    
    public override func viewDidLayoutSubviews() {
        if (self.previewLayer != nil) {
            self.previewLayer.frame = self.cameraView.layer.bounds
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let _ = self.captureSession, !self.captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let _ = self.captureSession, self.captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    private func addOverlayView() {
        self.overlayView = UIView()
        self.overlayView.layer.borderColor = UIColor.green.cgColor
        self.overlayView.layer.borderWidth = 2
        self.view.addSubview(self.overlayView)
        self.view.bringSubviewToFront(self.overlayView)
    }
    
    private func startCaptureSession() {
        self.captureSession = AVCaptureSession()
        guard (self.addVideoDeviceInput() && self.addMetadataOutput()) else {
            self.walletCoordinator.showErrorAlert(title: "Cannot start scanner", message: "Failed to start QR Scanner. Make sure the action is supported on your device and try again.", actionTitle: "Okay") { [weak self] in
                self?.captureSession = nil
                self?.dismiss(animated: true)
            }
            return
        }
        self.setupPreviewLayer()
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    private func addVideoDeviceInput() -> Bool {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return false }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return false
        }
        
        guard (self.captureSession.canAddInput(videoInput)) else {
            return false
        }
        self.captureSession.addInput(videoInput)
        return true
    }
    
    private func addMetadataOutput() -> Bool {
        let metadataOutput = AVCaptureMetadataOutput()
        
        guard (self.captureSession.canAddOutput(metadataOutput)) else {
            return false
        }
        self.captureSession.addOutput(metadataOutput)
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]
        return true
        
    }
    
    private func setupPreviewLayer() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer.frame = self.cameraView.layer.bounds
        self.previewLayer.videoGravity = .resizeAspectFill
        self.cameraView.layer.addSublayer(self.previewLayer)
    }
    
    @IBAction func onCancelClicked(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
}

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first else {
            self.overlayView?.frame = CGRect.zero
            return
        }
        
        guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject, readableObject.type == .qr,
              let rawQrContent = readableObject.stringValue else {
            return
        }
        self.captureSession?.stopRunning()
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        if let qrObject = self.previewLayer.transformedMetadataObject(for: readableObject) {
            let frame = qrObject.bounds
            let newOrigin = self.cameraView.convert(frame.origin, to: self.view)
            self.overlayView.frame = CGRect(origin: newOrigin, size: frame.size)
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.dismiss(animated: true) {
                self.viewModel.processQrCode(qrContent: rawQrContent)
            }
        }
    }
    
}
