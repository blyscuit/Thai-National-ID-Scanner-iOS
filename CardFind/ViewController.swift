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

class FaceDetectionViewController: UIViewController {
    @IBOutlet var faceView: FaceView!

  @IBOutlet var faceLaserLabel: UILabel!
  
  let session = AVCaptureSession()
  var previewLayer: AVCaptureVideoPreviewLayer!
  
    var cvimage: CVImageBuffer?
    
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

extension FaceDetectionViewController {
  @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
    
  }
}

// MARK: - Video Processing methods

extension FaceDetectionViewController {
  func configureCaptureSession() {
    // Define the capture device we want to use
    guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                               for: .video,
                                               position: .back) else {
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
    videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
    videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    
    // Add the video output to the capture session
    session.addOutput(videoOutput)
    
    let videoConnection = videoOutput.connection(with: .video)
    videoConnection?.videoOrientation = .portrait
    
    // Configure the preview layer
    previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = view.bounds
    view.layer.insertSublayer(previewLayer, at: 0)
  }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate methods

extension FaceDetectionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
    // 1
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }

    self.cvimage = imageBuffer
    
    // 2
    let detectFaceRequest = VNDetectRectanglesRequest(completionHandler: detectedFace)
    detectFaceRequest.minimumAspectRatio = 52.0 / 85.0
    detectFaceRequest.maximumAspectRatio = 56.0 / 85.0
    detectFaceRequest.minimumConfidence = 0.8
//    detectFaceRequest.maximumObservations = 10
    detectFaceRequest.minimumSize = 0.47
    // 3
    do {
      try sequenceHandler.perform(
        [detectFaceRequest],
        on: imageBuffer,
        orientation: .leftMirrored)
    } catch {
      print(error.localizedDescription)
    }
    
  }
    func convert(rect: CGRect) -> CGRect {
//        print(rect)
      // 1
//        var rect = CGRect(x: rect.origin.x * -1, y: rect.origin.y * -1, width: rect.width, height: rect.height)
      let origin = previewLayer.layerPointConverted(fromCaptureDevicePoint: rect.origin)
      
      // 2
      let size = previewLayer.layerPointConverted(fromCaptureDevicePoint: rect.size.cgPoint)
      
//        origin.x = origin.x - size.x
//        size.x += origin.x
//        print("x:   \(rect.origin.x)     y:  \(rect.origin.y)     w:  \(rect.width)   h:    \(rect.height)")
//        print("x:   \(origin.x)     y:  \(origin.y)     w:  \(size.x)   h:    \(size.y)")
        

      // 3
      return CGRect(origin: origin, size: size.cgSize)
    }
    
    func convertBack(rect: CGRect) -> CGRect {

        // 1
        let opposite = rect.origin + rect.size.cgPoint
        let origin = previewLayer.layerPointConverted(fromCaptureDevicePoint: rect.origin)

        // 2
        let opp = previewLayer.layerPointConverted(fromCaptureDevicePoint: opposite)

        // 3
        let size = (opp - origin).cgSize
        return CGRect(origin: origin, size: size)
    }
    func detectedFace(request: VNRequest, error: Error?) {
//        print(request)
      // 1
      guard
        let results = request.results as? [VNRectangleObservation],
        let result = results.first
        else {
          // 2
          faceView.clear()
          return
      }
        
        let _box = results.max{ a, b in a.boundingBox.height * a.boundingBox.width < b.boundingBox.height * b.boundingBox.width }
        
      // 3
        let box = _box!.boundingBox
      faceView.boundingBox = convertBack(rect: box)
        
        var uiImage: UIImage?
        if let cvBuffer = self.cvimage {
//            let rect = previewLayer.layerRectConverted(fromMetadataOutputRect: box)
            
            let ciImage = CIImage(cvPixelBuffer: cvBuffer)
            guard let image = ciImage.toUIImage() else {
              return
            }

            var transform = CGAffineTransform.identity
            transform = transform.scaledBy(x: image.size.width, y: -image.size.height)
            transform = transform.translatedBy(x: 0, y: -1)
            let rect = box.applying(transform)

            let scaleUp: CGFloat = 0.2
            let biggerRect = rect.insetBy(
              dx: -rect.size.width * scaleUp,
              dy: -rect.size.height * scaleUp
            )
            
            ciImage.cropped(to: biggerRect)
            
            
//            let ciImage = extractPerspectiveRect(_box!, from: cvBuffer)
            uiImage = UIImage(ciImage: ciImage)
            
        }
      // 4
      DispatchQueue.main.async {
        self.faceView.setNeedsDisplay()
        let vc = ImageViewViewController()
        vc.image = uiImage
        self.present(vc, animated: true, completion: nil)
      }
    }
    
    
}
