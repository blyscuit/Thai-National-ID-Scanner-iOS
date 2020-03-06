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
    @IBOutlet var faceView: UIImageView!

  @IBOutlet var faceLaserLabel: UILabel!
    
    var nationalIDProcessor = BlockTextProcessor()
  
  let session = AVCaptureSession()
  var previewLayer: AVCaptureVideoPreviewLayer!
  
    var cvimage: CVImageBuffer?
    
    var nextScanDate = Date().timeIntervalSinceNow
    
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
    configureCaptureSession()
    
    
    maxX = view.bounds.maxX
    midY = view.bounds.midY
    maxY = view.bounds.maxY
    
    session.startRunning()
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
    previewLayer.videoGravity = .resizeAspect
    previewLayer.frame = faceView.bounds
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
        orientation: .right)
        
        
    } catch {
      print(error.localizedDescription)
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
        
        let xCord = (maxX + 0) * CGFloat(cgImage.width)
        let yCord = ((1 - minY) + 0.006) * CGFloat(cgImage.height)
        let width = ((minX - maxX) + 0) * CGFloat(cgImage.width)
        let height = ((minY - maxY) + 0.012) * CGFloat(cgImage.height)
        
        guard let cropped = cgImage.cropping(to: CGRect(x: yCord, y: xCord, width: height, height: width)) else { return }
                
        if let tesseract = G8Tesseract(language: "DilleniaUPC") {
        // 2
        tesseract.engineMode = .tesseractOnly
        // 3
            tesseract.pageSegmentationMode = .sparseText
        // 4
            let rn = CGFloat.random(in: 1.3 ..< 1.4)
//            print(rn)
            tesseract.image = UIImage(cgImage: cropped, scale: 1.0, orientation: .left)//UIImage(cgImage: UIImage(cgImage: cropped, scale: 1.0, orientation: .left).preprocessedImage(radius: rn)!.cgImage! , scale: 1.0, orientation: .left)
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
