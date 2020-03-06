
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
import TesseractOCR


@available(iOS 13.0, *)
class AutoBuildInTextScanViewController: UIViewController {
    @IBOutlet var faceView: UIImageView!

  @IBOutlet var faceLaserLabel: UILabel!
    
    var nationalIDProcessor = BlockTextProcessor()
  
  let session = AVCaptureSession()
  var previewLayer: AVCaptureVideoPreviewLayer!
  
    var cvimage: CVImageBuffer?
    
    var nextScanDate = Date().timeIntervalSinceNow
    
    let ocrReader = OCRReader()
    var request: VNRecognizeTextRequest!

  let dataOutputQueue = DispatchQueue(
    label: "video data queue",
    qos: .userInitiated,
    attributes: [],
    autoreleaseFrequency: .workItem)

  var faceViewHidden = false
  
  var maxX: CGFloat = 0.0
  var midY: CGFloat = 0.0
  var maxY: CGFloat = 0.0

    var sequenceHandler = VNSequenceRequestHandler()
  override func viewDidLoad() {
    super.viewDidLoad()
    request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)

    configureCaptureSession()
    
    
    maxX = view.bounds.maxX
    midY = view.bounds.midY
    maxY = view.bounds.maxY
    
    session.startRunning()
  }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

        var results: String = ""

        for currentObservation in observations {
            let topCandidate = currentObservation.topCandidates(1)
            if let recognizedText = topCandidate.first {
                results.append(recognizedText.string)
                if currentObservation != observations.last {
                    results.append("\n")
                }
            }
        }
        
        if self.nationalIDProcessor.processText(text: results) == true {
            DispatchQueue.main.async {
            self.session.stopRunning()
            let vc = NationalIDResultViewController()
            vc.nationalID = self.nationalIDProcessor.nationalID
            self.present(vc, animated: true, completion: nil)
            }
        }
        
    }
    
    // MARK: - Bounding box drawing
    
    // Draw a box on screen. Must be called from main queue.
    var boxLayer = [CAShapeLayer]()
    func draw(rect: CGRect, color: CGColor) {
        let layer = CAShapeLayer()
        layer.opacity = 0.5
        layer.borderColor = color
        layer.borderWidth = 1
        layer.frame = rect
        boxLayer.append(layer)
//        faceView.insertSublayer(layer, at: 1)
    }
    
    // Remove all drawn boxes. Must be called on main queue.
    func removeBoxes() {
        for layer in boxLayer {
            layer.removeFromSuperlayer()
        }
        boxLayer.removeAll()
    }
    
    typealias ColoredBoxGroup = (color: CGColor, boxes: [CGRect])
    
    // Draws groups of colored boxes.
    func show(boxGroups: [ColoredBoxGroup]) {
        DispatchQueue.main.async {
            let layer = self.faceView
            self.removeBoxes()
            for boxGroup in boxGroups {
                let color = boxGroup.color
                for box in boxGroup.boxes {
//                    let rect = layer.layerRectConverted(fromMetadataOutputRect: box.applying(self.visionToAVFTransform))
//                    self.draw(rect: rect, color: color)
                }
            }
        }
    }
}

// MARK: - Gesture methods

@available(iOS 13.0, *)
extension AutoBuildInTextScanViewController {
  @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
    self.session.startRunning()
  }
}

// MARK: - Video Processing methods

@available(iOS 13.0, *)
extension AutoBuildInTextScanViewController {
  func configureCaptureSession() {
    

    session.sessionPreset = AVCaptureSession.Preset.photo
    let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
    
    // Define the capture device we want to use
    guard let camera = AVCaptureDevice.default(for: AVMediaType.video) else {
      fatalError("No front video camera available")
    }
    
    if camera.supportsSessionPreset(.hd4K3840x2160) {
        session.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
//        bufferAspectRatio = 3840.0 / 2160.0
    } else {
        session.sessionPreset = AVCaptureSession.Preset.hd1920x1080
//        bufferAspectRatio = 1920.0 / 1080.0
    }
    
    // Connect the camera to the capture session input
    do {
      let cameraInput = try AVCaptureDeviceInput(device: camera)
      session.addInput(cameraInput)
    } catch {
      fatalError(error.localizedDescription)
    }
    
//    // Create the video data output
//    let videoOutput = AVCaptureVideoDataOutput()
//    videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
//    videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
    
    
    var videoDataOutput = AVCaptureVideoDataOutput()

    // Configure video data output.
    videoDataOutput.alwaysDiscardsLateVideoFrames = true
    videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
    videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
    if session.canAddOutput(videoDataOutput) {
        session.addOutput(videoDataOutput)
        // NOTE:
        // There is a trade-off to be made here. Enabling stabilization will
        // give temporally more stable results and should help the recognizer
        // converge. But if it's enabled the VideoDataOutput buffers don't
        // match what's displayed on screen, which makes drawing bounding
        // boxes very hard. Disable it in this app to allow drawing detected
        // bounding boxes on screen.
        videoDataOutput.connection(with: AVMediaType.video)?.preferredVideoStabilizationMode = .off
    } else {
        print("Could not add VDO output")
        return
    }
    
    // Set zoom and autofocus to help focus on very small text.
    do {
        try captureDevice!.lockForConfiguration()
        captureDevice!.videoZoomFactor = 1
        captureDevice!.autoFocusRangeRestriction = .near
        captureDevice!.unlockForConfiguration()
    } catch {
        print("Could not set zoom level due to error: \(error)")
        return
    }
    
    // Add the video output to the capture session
//    session.addOutput(videoOutput)
    
    // Configure the preview layer
    previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = faceView.bounds
    faceView.layer.insertSublayer(previewLayer, at: 0)
  }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate methods

@available(iOS 13.0, *)
extension AutoBuildInTextScanViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
    
    if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
        // Configure for running in real-time.
        request.recognitionLevel = .accurate
        // Language correction won't help recognizing phone numbers. It also
        // makes recognition slower.
        request.usesLanguageCorrection = false
        // Only run on the region of interest for maximum speed.
//        request.regionOfInterest = regionOfInterest

        request.recognitionLanguages = ["en"]
        request.customWords = ["Identification Number", "Date of Birth", "Last name", "Date of Issue", "Date of Expiry", "Name"]
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            print(error)
        }
    }
    
  }
    func detectedFace(request: VNRequest, error: Error?) {
//        print(request)
      // 1
      guard
        let results = request.results as? [VNTextObservation],
        let result = results.first
        else {
          // 2
            DispatchQueue.main.async() {
                self.faceView.layer.sublayers?.removeSubrange(1...)
            }
          return
      }

        
        if results.count > 1 && Date().timeIntervalSince1970 > self.nextScanDate {
//            self.session.stopRunning()
//            DispatchQueue.main.async {
//                self.faceView.layer.sublayers?.removeSubrange(1...)

            self.nextScanDate = Date().timeIntervalSince1970 + 0.1
                
                guard let cvBuffer = self.cvimage else {
                    return
                }
                let ciImage = CIImage(cvPixelBuffer: cvBuffer)

                let filter = CIFilter(name: "CILanczosScaleTransform")!
                filter.setValue(ciImage, forKey: "inputImage")
//                filter.setValue(self.previewLayer.frame.width / self.previewLayer.frame.height, forKey: "inputScale")
                filter.setValue(self.previewLayer.frame.width / self.previewLayer.frame.height, forKey: "inputAspectRatio")
                let outputImage = filter.value(forKey: "outputImage") as! CIImage

                let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
                context.createCGImage(outputImage, from: outputImage.extent)

                guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                    return
                }
                
            let rn = CGFloat.random(in: 1.3 ..< 1.4)
            print(rn)
            ocrReader.performOCR(on: UIImage(cgImage: cgImage, scale: 1.0, orientation: .left).preprocessedImage(radius: rn)!.cgImage, recognitionLevel: .accurate) { (result) in
                if self.nationalIDProcessor.processText(text: result) == true {
                    self.session.stopRunning()
                    let vc = NationalIDResultViewController()
                    vc.nationalID = self.nationalIDProcessor.nationalID
                    self.present(vc, animated: true, completion: nil)
                }
            }
            
                for region in results {
                    self.cropWord(cgImage: cgImage, box: region)
                }

//                }
//                let vc = ImageViewViewController()
//                    vc.presentationController?.delegate = self
//                vc.images = self.cropped
    //            self.session.stopRunning()
//                self.present(vc, animated: true, completion: nil)
                
        } else {
            DispatchQueue.main.async() {
                
            self.faceView.layer.sublayers?.removeSubrange(1...)
            for region in results {
                self.highlightWord(box: region)
                }
            }
        }

    }
    
    func cropWord(cgImage: CGImage, box: VNTextObservation) {
        guard let boxes = box.characterBoxes else {
            return
        }

        var maxX: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9999.0
        var minY: CGFloat = 0.0
        
        for char in boxes {
            if char.bottomLeft.x < maxX {
                maxX = char.bottomLeft.x
            }
            if char.bottomRight.x > minX {
                minX = char.bottomRight.x
            }
            if char.bottomRight.y < maxY {
                maxY = char.bottomRight.y
            }
            if char.topRight.y > minY {
                minY = char.topRight.y
            }
        }
        
        let xCord = (maxX + 0.005) * CGFloat(cgImage.width)
        let yCord = ((1 - minY) + 0.020) * CGFloat(cgImage.height)
        let width = ((minX - maxX) + 0.005) * CGFloat(cgImage.width)
        let height = ((minY - maxY) + 0.040) * CGFloat(cgImage.height)
        
        guard let cropped = cgImage.cropping(to: CGRect(x: yCord, y: xCord, width: height, height: width)) else { return }
                
//        let rn = CGFloat.random(in: 1.3 ..< 1.4)
//        print(rn)
//        ocrReader.performOCR(on: UIImage(cgImage: cropped, scale: 1.0, orientation: .left).preprocessedImage(radius: rn)!.cgImage, recognitionLevel: .accurate) { (result) in
//            if self.nationalIDProcessor.processText(text: result) == true {
//                self.session.stopRunning()
//                let vc = NationalIDResultViewController()
//                vc.nationalID = self.nationalIDProcessor.nationalID
//                self.present(vc, animated: true, completion: nil)
//            }
//        }
        
//        if let tesseract = G8Tesseract(language: "DilleniaUPC") {
//        // 2
//        tesseract.engineMode = .tesseractOnly
//        // 3
//            tesseract.pageSegmentationMode = .sparseText
//        // 4
//            let rn = CGFloat.random(in: 1.3 ..< 1.4)
////            print(rn)
//            tesseract.image = UIImage(cgImage: cropped, scale: 1.0, orientation: .left)//UIImage(cgImage: UIImage(cgImage: cropped, scale: 1.0, orientation: .left).preprocessedImage(radius: rn)!.cgImage! , scale: 1.0, orientation: .left)
//        // 5
//            if tesseract.recognize() {
//                // 6
////                  DispatchQueue.main.async {
//                    if self.nationalIDProcessor.processText(text: tesseract.recognizedText) == true {
//                        self.session.stopRunning()
//                        let vc = NationalIDResultViewController()
//                        vc.nationalID = self.nationalIDProcessor.nationalID
//                        self.present(vc, animated: true, completion: nil)
//                    }
////                }
//            }
//        }
    }
    
    func highlightWord(box: VNTextObservation) {
        guard let boxes = box.characterBoxes else {
            return
        }
        var maxX: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9999.0
        var minY: CGFloat = 0.0
        
        for char in boxes {
            if char.bottomLeft.x < maxX {
                maxX = char.bottomLeft.x
            }
            if char.bottomRight.x > minX {
                minX = char.bottomRight.x
            }
            if char.bottomRight.y < maxY {
                maxY = char.bottomRight.y
            }
            if char.topRight.y > minY {
                minY = char.topRight.y
            }
        }
        
        let xCord = maxX * self.faceView.frame.size.width
        let yCord = (1 - minY) * self.faceView.frame.size.height
        let width = (minX - maxX) * self.faceView.frame.size.width
        let height = (minY - maxY) * self.faceView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.black.withAlphaComponent(0.2).cgColor
        

        DispatchQueue.main.async() {
            self.faceView.layer.addSublayer(outline)
        }
    }
    
}
