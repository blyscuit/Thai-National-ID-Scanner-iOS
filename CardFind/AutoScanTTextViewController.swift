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


class AutoScanTTextDetectionViewController: UIViewController {
    var maskLayer = CAShapeLayer()
    @IBOutlet weak var cutoutView: UIView!

    @IBOutlet var faceView: UIImageView!

  @IBOutlet var faceLaserLabel: UILabel!
    
    var nationalIDProcessor = BlockTextProcessor()
  
  let session = AVCaptureSession()
  var previewLayer: AVCaptureVideoPreviewLayer!
  
    var cvimage: CVImageBuffer?
    
    var nextScanDate = Date().timeIntervalSinceNow
    let ocrReader = OCRReader()
    
    var regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)

  let dataOutputQueue = DispatchQueue(
    label: "video data queue",
    qos: .userInitiated,
    attributes: [],
    autoreleaseFrequency: .workItem)

  var faceViewHidden = false
  
  var maxX: CGFloat = 0.0
  var midY: CGFloat = 0.0
  var maxY: CGFloat = 0.0
    
    var bufferAspectRatio = 0.0

    var sequenceHandler = VNSequenceRequestHandler()
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Set up cutout view.
    cutoutView.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
    maskLayer.backgroundColor = UIColor.clear.cgColor
    maskLayer.fillRule = .evenOdd
    cutoutView.layer.mask = maskLayer
    
    configureCaptureSession()
    
    
    maxX = view.bounds.maxX
    midY = view.bounds.midY
    maxY = view.bounds.maxY
    
    session.startRunning()
    
    // Create the mask.
    let path = UIBezierPath(rect: cutoutView.frame)
    path.append(UIBezierPath(rect: CGRect(x: 100, y: 100, width: 200, height: 300)))
    maskLayer.path = path.cgPath
  }
}

// MARK: - Gesture methods

extension AutoScanTTextDetectionViewController {
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        self.session.startRunning()
    }
}

// MARK: - Video Processing methods

extension AutoScanTTextDetectionViewController {
  func configureCaptureSession() {
    

    session.sessionPreset = AVCaptureSession.Preset.photo
    
    // Define the capture device we want to use
    guard let camera = AVCaptureDevice.default(for: AVMediaType.video) else {
      fatalError("No front video camera available")
    }
    
    
    do {
        try camera.lockForConfiguration()
        camera.videoZoomFactor = 2.5
        camera.autoFocusRangeRestriction = .near
        camera.unlockForConfiguration()
    } catch {
        print("Could not set zoom level due to error: \(error)")
        return
    }
    
    if camera.supportsSessionPreset(.hd4K3840x2160) {
            session.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
            bufferAspectRatio = 3840.0 / 2160.0
        } else {
            session.sessionPreset = AVCaptureSession.Preset.hd1920x1080
            bufferAspectRatio = 1920.0 / 1080.0
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
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = faceView.bounds
    previewLayer.opacity = 0.5
    faceView.layer.insertSublayer(previewLayer, at: 0)
  }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate methods

extension AutoScanTTextDetectionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
    // 1
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }
    
//    if Date().timeIntervalSince1970 > self.nextScanDate {
        self.cvimage = imageBuffer
//    }
    
    // 2
    let detectFaceRequest = VNDetectTextRectanglesRequest(completionHandler: detectedFace)
    detectFaceRequest.reportCharacterBoxes = true
    // 3
    do {
      try sequenceHandler.perform(
        [detectFaceRequest],
        on: imageBuffer,
        orientation: .up)
        
        
    } catch {
      print(error.localizedDescription)
    }
    
  }
    func detectedFace(request: VNRequest, error: Error?) {
//        print(request)
      // 1
      guard
        let results = request.results as? [VNTextObservation], results.count>0
        else {
          // 2
            DispatchQueue.main.async() {
                self.faceView.layer.sublayers?.removeSubrange(1...)
            }
          return
      }

        
        if results.count > 1 && Date().timeIntervalSince1970 > self.nextScanDate {
//            self.session.stopRunning()
            DispatchQueue.main.async {
                self.faceView.layer.sublayers?.removeSubrange(1...)
            }

            self.nextScanDate = Date().timeIntervalSince1970 + 0.1
                
                guard let cvBuffer = self.cvimage else {
                    return
                }
                let ciImage = CIImage(cvPixelBuffer: cvBuffer)

                let filter = CIFilter(name: "CILanczosScaleTransform")!
                filter.setValue(ciImage, forKey: "inputImage")
//                filter.setValue(self.previewLayer.frame.width / self.previewLayer.frame.height, forKey: "inputScale")
//                filter.setValue(1 / (bufferAspectRatio), forKey: "inputAspectRatio")
                let outputImage = filter.value(forKey: "outputImage") as! CIImage

                let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
                context.createCGImage(outputImage, from: outputImage.extent)

                guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                    return
                }
                
            
            
//                for region in results {
//                    self.cropWord(cgImage: cgImage, box: region)
//                    self.highlightWord(box: region)
//                }
            ocrReader.performOCR(on: cgImage, recognitionLevel: .accurate) { (result) in
                if self.nationalIDProcessor.processText(text: result) == true {
                    DispatchQueue.main.async {
                        self.session.stopRunning()
                        let vc = NationalIDResultViewController()
                        vc.nationalID = self.nationalIDProcessor.nationalID
                        self.present(vc, animated: true, completion: nil)
                        
                    }
                }
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
        
        var outlineWidth: CGFloat = 0
        var outlineHeight: CGFloat = 0
        
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
        
        outlineWidth = ((boxes.first?.bottomRight.x ?? 0) - (boxes.first?.bottomLeft.x ?? 0)) * 1.8
        outlineHeight = ((boxes.first?.bottomRight.y ?? 0) - (boxes.first?.topRight.y ?? 0)) * 1.8
        
        let xCord = (maxX + outlineWidth) * CGFloat(cgImage.width)
        let yCord = ((1 - minY) + outlineHeight) * CGFloat(cgImage.height)
        let width = ((minX - maxX) + (outlineWidth * 2)) * CGFloat(cgImage.width)
        let height = ((minY - maxY) + (outlineHeight * 2)) * CGFloat(cgImage.height)
        
        guard let cropped = cgImage.cropping(to: CGRect(x: xCord, y: yCord, width: width, height: height)) else { return }
//        guard let cropped = cgImage.cropping(to: CGRect(x: yCord, y: xCord, width: height, height: width)) else { return }

        let rn = CGFloat.random(in: 2 ..< 2.1)

        let i = UIImage(cgImage: cgImage, scale: 1.0, orientation: .left)//UIImage(cgImage: UIImage(cgImage: cropped, scale: 1.0, orientation: .left).preprocessedImage(radius: rn)!.cgImage! , scale: 1.0, orientation: .left)
        DispatchQueue.main.async {
            self.faceView.image = i
        }
        
        ocrReader.performOCR(on: i.cgImage, recognitionLevel: .accurate) { (result) in
            if self.nationalIDProcessor.processText(text: result) == true {
                self.session.stopRunning()
                let vc = NationalIDResultViewController()
                vc.nationalID = self.nationalIDProcessor.nationalID
                self.present(vc, animated: true, completion: nil)
            }
        }
        return
        
        if let tesseract = G8Tesseract(language: "DilleniaUPC") {
        // 2
        tesseract.engineMode = .tesseractOnly
        // 3
            tesseract.pageSegmentationMode = .singleBlock
        // 4
            let rn = CGFloat.random(in: 1.3 ..< 1.4)
//            print(rn)
            tesseract.image = i
            DispatchQueue.main.async {
                self.faceView.image = tesseract.image
            }
            
            
            // 5
            if tesseract.recognize() {
                // 6
//                  DispatchQueue.main.async {
                    if self.nationalIDProcessor.processText(text: tesseract.recognizedText) == true {
                        self.session.stopRunning()
                        let vc = NationalIDResultViewController()
                        vc.nationalID = self.nationalIDProcessor.nationalID
                        self.present(vc, animated: true, completion: nil)
                    }
//                }
            }
        }
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
        DispatchQueue.main.async {

        let xCord = maxX * self.faceView.frame.size.width
        let yCord = (1 - minY) * self.faceView.frame.size.height
        let width = (minX - maxX) * self.faceView.frame.size.width
        let height = (minY - maxY) * self.faceView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.frame = CGRect(x: yCord, y: xCord, width: height, height: width)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.black.withAlphaComponent(0.2).cgColor
        

            DispatchQueue.main.async() {
                self.faceView.layer.addSublayer(outline)
            }
        }
    }
    
    
    func highlightLetters(box: VNRectangleObservation) {
        DispatchQueue.main.async() {

        let xCord = box.topLeft.x * self.faceView.frame.size.width
        let yCord = (1 - box.topLeft.y) * self.faceView.frame.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * self.faceView.frame.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * self.faceView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 1.0
        outline.borderColor = UIColor.blue.cgColor
        
        DispatchQueue.main.async() {

            self.faceView.layer.addSublayer(outline)
        }
    }
    }
    
}
