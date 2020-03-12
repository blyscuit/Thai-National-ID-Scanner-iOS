//
//  ImageViewViewController.swift
//  CardFind
//
//  Created by Pisit W on 28/2/2563 BE.
//  Copyright © 2563 23. All rights reserved.
//

import UIKit
//import SwiftOCR
import TesseractOCR
import GPUImage
import Firebase

class ImageViewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var image: UIImage?
    var images: [UIImage]?


    var collectionview: UICollectionView!
    var cellId = "Cell"
    
//    let swiftOCRInstance = SwiftOCR(recognizableCharacters: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", network: FFNN.fromFile(Bundle.main.url(forResource: "OCR-Network", withExtension: nil)!)!)

    let vision = Vision.vision()
    var textRecognizer: VisionTextRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create an instance of UICollectionViewFlowLayout since you cant
        // Initialize UICollectionView without a layout
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: view.frame.width, height: view.frame.height)
        layout.scrollDirection = .horizontal

        collectionview = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionview.dataSource = self
        collectionview.delegate = self
        collectionview.register(FreelancerCell.self, forCellWithReuseIdentifier: cellId)
        collectionview.showsVerticalScrollIndicator = true
        collectionview.backgroundColor = UIColor.white
        collectionview.isPagingEnabled = true
        self.view.addSubview(collectionview)


        // Or, to provide language hints to assist with language detection:
        // See https://cloud.google.com/vision/docs/languages for supported languages
        let options = VisionCloudTextRecognizerOptions()
        options.languageHints = ["en"]
        textRecognizer = vision.onDeviceTextRecognizer()//.cloudTextRecognizer(options: options)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images?.count ?? ((image != nil) ? 1 : 0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionview.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! FreelancerCell
        cell.profileImageButton.image = (((images?.count ?? 0) > indexPath.row) ? (images![indexPath.row]) : UIImage())
        
        let image = VisionImage(image: cell.profileImageButton.image!)
        let metadata = VisionImageMetadata()
        metadata.orientation = imageOrientation(
            deviceOrientation: UIDevice.current.orientation,
            cameraPosition: .back
        )
        image.metadata = metadata
        textRecognizer.process(image) { result, error in
          guard error == nil, let result = result else {
            return
          }
            let resultText = result.text
            DispatchQueue.main.async {
                cell.textview.text = resultText
            }
                
//            for block in result.blocks {
//                let blockText = block.text
//                let blockConfidence = block.confidence
//                let blockLanguages = block.recognizedLanguages
//                let blockCornerPoints = block.cornerPoints
//                let blockFrame = block.frame
//                for line in block.lines {
//                    let lineText = line.text
//                    let lineConfidence = line.confidence
//                    let lineLanguages = line.recognizedLanguages
//                    let lineCornerPoints = line.cornerPoints
//                    let lineFrame = line.frame
//                    for element in line.elements {
//                        let elementText = element.text
//                        let elementConfidence = element.confidence
//                        let elementLanguages = element.recognizedLanguages
//                        let elementCornerPoints = element.cornerPoints
//                        let elementFrame = element.frame
//                    }
//                }
//            }
          // Recognized text
        }
        
//        swiftOCRInstance.recognize(((images?.count ?? 0) > indexPath.row) ? (images![indexPath.row]) : UIImage()) { recognizedString in
//            DispatchQueue.main.async {
//                cell.textview.text = recognizedString
//            }
//        }
        
        if let tesseract = G8Tesseract(language: "eng") {
          // 2
          tesseract.engineMode = .tesseractOnly
          // 3
            tesseract.pageSegmentationMode = .singleBlock
          // 4
            tesseract.image = UIImage(cgImage: cell.profileImageButton.image!.preprocessedImage()!.cgImage!, scale: 1.0, orientation: .right)
          // 5
          tesseract.recognize()
          // 6
            DispatchQueue.main.async {
                            cell.textview.text = tesseract.recognizedText
                        }
                    }
        
        return cell
    }


}

extension UIImage {
    func preprocessedImage(radius: CGFloat = 1.0) -> UIImage? {
      // 1
      let stillImageFilter = GPUImageAdaptiveThresholdFilter()
      // 2
        stillImageFilter.blurRadiusInPixels = radius
      // 3
      let filteredImage = stillImageFilter.image(byFilteringImage: self)
      // 4
      return filteredImage
    }
}







class FreelancerCell: UICollectionViewCell {


    let profileImageButton: UIImageView = {
        let button = UIImageView()
        button.backgroundColor = UIColor.white
        button.clipsToBounds = true
        button.contentMode = .scaleAspectFit
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let textview: UILabel = {
        let t = UILabel()
        t.textAlignment = .center
        t.translatesAutoresizingMaskIntoConstraints = false
        t.numberOfLines = 0
        return t
    }()


    override init(frame: CGRect) {
        super.init(frame: frame)

        addViews()
    }




    func addViews(){

        addSubview(profileImageButton)
        addSubview(textview)

        profileImageButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 0).isActive = true
        profileImageButton.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        profileImageButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        profileImageButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        textview.leftAnchor.constraint(equalTo: leftAnchor, constant: 0).isActive = true
        textview.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        textview.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
//        textview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

    }



    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

func imageOrientation(
    deviceOrientation: UIDeviceOrientation,
    cameraPosition: AVCaptureDevice.Position
    ) -> VisionDetectorImageOrientation {
    switch deviceOrientation {
    case .portrait:
        return cameraPosition == .front ? .leftTop : .rightTop
    case .landscapeLeft:
        return cameraPosition == .front ? .bottomLeft : .topLeft
    case .portraitUpsideDown:
        return cameraPosition == .front ? .rightBottom : .leftBottom
    case .landscapeRight:
        return cameraPosition == .front ? .topRight : .bottomRight
    case .faceDown, .faceUp, .unknown:
        return .leftTop
    }
}
