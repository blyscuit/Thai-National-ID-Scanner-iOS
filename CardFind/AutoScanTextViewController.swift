/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import AVFoundation
import UIKit
import Vision
import ImageIO
import Firebase


class AutoTextDetectionViewController: UIViewController {
    @IBOutlet var faceView: UIImageView!

  @IBOutlet var faceLaserLabel: UILabel!
  
  let session = AVCaptureSession()
  var previewLayer: AVCaptureVideoPreviewLayer!
  
    var cvimage: CVImageBuffer?
    
    var cropped: [UIImage] = []
    
    let vision = Vision.vision()
    var textRecognizer: VisionTextRecognizer!
    
  let dataOutputQueue = DispatchQueue(
    label: "video data queue",
    qos: .userInitiated,
    attributes: [],
    autoreleaseFrequency: .workItem)

  var faceViewHidden = false

    var nationalIDProcessor = BlockTextProcessor()

  var maxX: CGFloat = 0.0
  var midY: CGFloat = 0.0
  var maxY: CGFloat = 0.0

    var cardPosition: VisionDetectorImageOrientation = .rightTop
    var cardDetected: Bool = false
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    textRecognizer = vision.onDeviceTextRecognizer()
    
    configureCaptureSession()
    
    
    maxX = view.bounds.maxX
    midY = view.bounds.midY
    maxY = view.bounds.maxY
    
    session.startRunning()
    
  }
}

// MARK: - Gesture methods

extension AutoTextDetectionViewController {
  @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
    self.session.startRunning()
  }
}

// MARK: - Video Processing methods

extension AutoTextDetectionViewController {
  func configureCaptureSession() {
    

    session.sessionPreset = AVCaptureSession.Preset.photo
    let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
    
    // Define the capture device we want to use
    guard let camera = AVCaptureDevice.default(for: AVMediaType.video) else {
      fatalError("No front video camera available")
    }
    
    // Connect the camera to the capture session input
    do {
      let cameraInput = try AVCaptureDeviceInput(device: camera)
      session.addInput(cameraInput)
    } catch {
      fatalError(error.localizedDescription)
    }
    
    // Create the video data output
    let videoOutput = AVCaptureVideoDataOutput()
    videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
    videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
    
    
    // Add the video output to the capture session
    session.addOutput(videoOutput)
    
    // Configure the preview layer
    previewLayer = AVCaptureVideoPreviewLayer(session: session)
//    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = faceView.bounds
    faceView.layer.insertSublayer(previewLayer, at: 0)
  }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate methods

extension AutoTextDetectionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
    // 3
    do {
        
        let cameraPosition = AVCaptureDevice.Position.back  // Set to the capture device you used.
        let metadata = VisionImageMetadata()
        metadata.orientation = cardPosition // .rightTop // .leftBottom
        let visionImage = VisionImage(buffer: sampleBuffer)
        visionImage.metadata = metadata
        textRecognizer.process(visionImage) { result, error in
          guard error == nil, let result = result else {
            return
          }
            let componentsCount = result.text.components(separatedBy: "\n").count
            self.cardDetected = componentsCount > 18
//            if componentsCount > 2 && componentsCount < 11 {
//                self.cardPosition = self.cardPosition == .rightTop ? .leftBottom : .rightTop
//            }
            
//            DispatchQueue.main.async {
//                self.faceLaserLabel.text = result.text
//            for block in result.blocks {
//                            let blockText = block.text
//                            let blockConfidence = block.confidence
//                            let blockLanguages = block.recognizedLanguages
//                            let blockCornerPoints = block.cornerPoints
//                            let blockFrame = block.frame
//
//                        }
            
          // Recognized text
            if self.nationalIDProcessor.processText(text: result.text) == true {
                self.session.stopRunning()

                let vc = NationalIDResultViewController()
                vc.presentationController?.delegate = self
                vc.nationalID = self.nationalIDProcessor.nationalID
                self.present(vc, animated: true, completion: nil)
            }
        }
        
        
        if self.self.cardDetected {
                let metadataUp = VisionImageMetadata()
                metadataUp.orientation = .leftBottom
                let visionImageUp = VisionImage(buffer: sampleBuffer)
                visionImageUp.metadata = metadataUp
                textRecognizer.process(visionImageUp) { result, error in
                  guard error == nil, let result = result else {
                    return
                  }
                    
                  // Recognized text
                    if self.nationalIDProcessor.processText(text: result.text) == true {
                        self.session.stopRunning()

                        let vc = NationalIDResultViewController()
                        vc.presentationController?.delegate = self
                        vc.nationalID = self.nationalIDProcessor.nationalID
                        self.present(vc, animated: true, completion: nil)
                    }
                }
        }
        
    } catch {
      print(error.localizedDescription)
    }
    
  }
    
}

extension AutoTextDetectionViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if session != nil , !session.isRunning {
            self.nationalIDProcessor.resetData()
            session.startRunning()
        }
    }
}

