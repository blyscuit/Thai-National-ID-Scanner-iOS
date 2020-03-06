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


class TestIDViewController: UIViewController {
    @IBOutlet var faceView: UIImageView!

  @IBOutlet var faceLaserLabel: UILabel!
    
    var nationalIDProcessor = BlockTextProcessor()
  
    
    var nextScanDate = Date().timeIntervalSinceNow

  var faceViewHidden = false
  
  var maxX: CGFloat = 0.0
  var midY: CGFloat = 0.0
  var maxY: CGFloat = 0.0

    var sequenceHandler = VNSequenceRequestHandler()
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    maxX = view.bounds.maxX
    midY = view.bounds.midY
    maxY = view.bounds.maxY
    
                    
            
    
  }
}

// MARK: - Gesture methods

extension TestIDViewController {
  @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
    
    let ocrReader = OCRReader()
    ocrReader.performOCR(on:  #imageLiteral(resourceName: "id-card-example").cgImage, recognitionLevel: .accurate)
//    if let tesseract = G8Tesseract(language: "DilleniaUPC") {
//            // 2
//            tesseract.engineMode = .tesseractOnly
//            // 3
//                tesseract.pageSegmentationMode = .singleBlock
//            // 4
//        let rn = CGFloat.random(in: 1.3 ..< 1.4)
//        print(rn)
//        tesseract.image =  #imageLiteral(resourceName: "id-card-example").preprocessedImage(radius: rn)!
//
//        self.faceView.image = tesseract.image
//            // 5
//                if tesseract.recognize() {
//                    // 6
//    //                  DispatchQueue.main.async {
//                        if self.nationalIDProcessor.processText(text: tesseract.recognizedText) == true {
//                            let vc = NationalIDResultViewController()
//                            vc.nationalID = self.nationalIDProcessor.nationalID
//                            self.present(vc, animated: true, completion: nil)
//                        }
//    //                }
//                }
//            }
  }
}


// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate methods

extension TestIDViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
    // 1
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }
    
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

        
        if results.count > 17 && Date().timeIntervalSince1970 > self.nextScanDate {
//            self.session.stopRunning()
//            DispatchQueue.main.async {
//                self.faceView.layer.sublayers?.removeSubrange(1...)

//            self.nextScanDate = Date().timeIntervalSince1970 + 1
//
//                let ciImage = CIImage(cvPixelBuffer: cvBuffer)
//
//                let filter = CIFilter(name: "CILanczosScaleTransform")!
//                filter.setValue(ciImage, forKey: "inputImage")
////                filter.setValue(self.previewLayer.frame.width / self.previewLayer.frame.height, forKey: "inputScale")
//                filter.setValue(self.previewLayer.frame.width / self.previewLayer.frame.height, forKey: "inputAspectRatio")
//                let outputImage = filter.value(forKey: "outputImage") as! CIImage
//
//                let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
//                context.createCGImage(outputImage, from: outputImage.extent)
//
//                guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
//                    return
//                }
//
//
//
//                for region in results {
//                    self.cropWord(cgImage: cgImage, box: region)
//                }

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
        
        let xCord = (maxX + 0.024) * CGFloat(cgImage.width)
        let yCord = ((1 - minY) + 0.025) * CGFloat(cgImage.height)
        let width = ((minX - maxX) + 0.048) * CGFloat(cgImage.width)
        let height = ((minY - maxY) + 0.05) * CGFloat(cgImage.height)
        
        guard let cropped = cgImage.cropping(to: CGRect(x: yCord, y: xCord, width: height, height: width)) else { return }
                
        if let tesseract = G8Tesseract(language: "DilleniaUPC") {
        // 2
        tesseract.engineMode = .tesseractOnly
        // 3
            tesseract.pageSegmentationMode = .singleBlock
        // 4
            tesseract.image = UIImage(cgImage: cropped, scale: 1.0, orientation: .left)
        // 5
            if tesseract.recognize() {
                // 6
//                  DispatchQueue.main.async {
                    if self.nationalIDProcessor.processText(text: tesseract.recognizedText) == true {
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

class OCRReader {
    func performOCR(on image: CGImage?, recognitionLevel: VNRequestTextRecognitionLevel, completion: ((String)->())? = nil)  {
        guard let image = image else { return }
        let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
        
        var results: String = ""
        
        if #available(iOS 13.0, *) {
            let request = VNRecognizeTextRequest  { (request, error) in
                if let error = error {
                    print(error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                
                for currentObservation in observations {
                    let topCandidate = currentObservation.topCandidates(1)
                    if let recognizedText = topCandidate.first {
                        results.append("\n")
                        results.append(recognizedText.string)
                    }
                }
                completion?(results) ?? print(results)
            }

            request.recognitionLevel = recognitionLevel
            request.recognitionLanguages = ["en"]
            request.usesLanguageCorrection = false
            request.customWords = ["Identification Number", "Date of Birth", "Last name", "Date of Issue", "Date of Expiry", "Name"]

            try? requestHandler.perform([request])
        } else {
            // Fallback on earlier versions
        }
    }
}
