//
//  TextScan.swift
//  CardFind
//
//  Created by Pisit W on 28/2/2563 BE.
//  Copyright © 2563 23. All rights reserved.
//

import UIKit
import Vision
import Firebase
//class TextScan {
//    func Scan(image: UIImage) {
//        let handler = VNImageRequestHandler(
//          cgImage: cgImage,
//          orientation: inferOrientation(image: image),
//          options: [VNImageOption: Any]()
//        )
//
//        let request = VNDetectTextRectanglesRequest(completionHandler: { [weak self] request, error in
//          DispatchQueue.main.async {
//            self?.handle(image: image, request: request, error: error)
//          }
//        })
//
//        request.reportCharacterBoxes = true
//
//        do {
//          try handler.perform([request])
//        } catch {
//          print(error as Any)
//        }
//    }
//}

class BlockTextProcessor {
    var nationalID: NationalID!
    
    let lastName = "Last name"
    let name = "Name"
    let id = "n Number"
    
    let nationalIDRegex = "[0-9]{1} [0-9]{4} [0-9]{5} [0-9]{2} [0-9]{1}"

    let idPredicate = NSPredicate(format:"SELF MATCHES %@", "[0-9]{1} [0-9]{4} [0-9]{5} [0-9]{2} [0-9]{1}")
    
    func processText(text: String?) -> Bool {
        if nationalID == nil {
            nationalID = NationalID()
        }
        guard let text = text else {
            return nationalID.isCompleted
        }
        var splitted = text.components(separatedBy: "\n")
        print(splitted)
        splitted.removeAll { $0 == "" }
        for text in splitted.enumerated() {
            let _text = text.element
            if _text.contains(lastName) {
                let last = _text.components(separatedBy: lastName).last
                if last?.count ?? 0 > 0 {
                    nationalID.lastName = last
                }
            } else if _text.contains(name) {
                let last = _text.components(separatedBy: name).last
                if last?.count ?? 0 > 0 {
                    nationalID.firstName = last
                }
            } else if (_text.contains(id) || _text.contains("n Nuxnher")) && _text.contains("Id") {
                let last = _text.components(separatedBy: id).last
                if last?.count ?? 0 > 0 {
                    nationalID.nID = last
                }
            } else if idPredicate.evaluate(with: _text) {
                nationalID.nID = _text
            } else if let range = _text.range(of: nationalIDRegex, options: .regularExpression, range: nil, locale: nil) {
                guard let nsString = _text as NSString? else { continue }
                let n1 = NSRange(range, in: _text)
                nationalID.nID = nsString.substring(with: n1)
            } else if _text.contains("Birth") && _text.contains("Date") {
                guard let dobText = _text.components(separatedBy: "Birth").last else { continue }
                let date = cardStringToDate(dobText)
                nationalID.birthDate = date
            } else if _text.contains("ssue") && _text.contains("Date") {
                if text.offset == 0 { continue }
                let dText = splitted[text.offset - 1]
                let date = cardStringToDate(dText)
                nationalID.issuedDate = date
            } else if _text.contains("Exp") && _text.contains("Date") {
                if text.offset == 0 { continue }
                let dText = splitted[text.offset - 1]
                let date = cardStringToDate(dText)
                nationalID.expiredDate = date
            }
        }
        return nationalID.isCompleted
    }
    
    func cardStringToDate(_ text: String) -> Date? {
        var dateArray = text.replacingOccurrences(of: ".", with: "").components(separatedBy: " ")
        dateArray.removeAll { $0 == "" }
        if dateArray.first?.count == 1 {
            dateArray[0] = "0" + dateArray[0]
        }
        let formattedDob = dateArray.joined(separator: "-")
        let date = Date.from(text: formattedDob, dateFormat: "dd-MMM-yyyy")
        return date
    }
    
    func resetData() {
        nationalID = NationalID()
    }
}

struct NationalID: IDable {
    var dataCount: Int {
        return 6
    }
    
    var dataArray: [String?] {
        return [nID, firstName, lastName, (birthDate != nil) ? "\(birthDate!.toString(dateFormat: "dd MMMM yyyy"))" : "", (issuedDate != nil) ? "\(issuedDate!.toString(dateFormat: "dd MMMM yyyy"))" : "", (expiredDate != nil) ? "\(expiredDate!.toString(dateFormat: "dd MMMM yyyy"))" : ""]
    }
    
    var firstName, lastName, nID: String?
    var birthDate, issuedDate, expiredDate: Date?
    
    var isCompleted: Bool {
        guard let firstName = firstName, let lastName = lastName, let nID = nID, let birthDate = birthDate
            , let issuedDate = issuedDate, let expiredDate = expiredDate
            , firstName.count > 0, lastName.count > 0 , nID.count > 0
            else { return false }
        return true
    }
}

protocol IDable {
    var dataCount: Int {
        get
    }
    
    var dataArray: [String?] {
        get
    }
    
    var isCompleted: Bool {
        get
    }
}

extension Date {
    static func from(text: String, dateFormat format: String ) -> Date?
    {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)!
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        let calendar = Calendar(identifier: .gregorian)
        dateFormatter.calendar = calendar
        return dateFormatter.date(from: text)
    }
    
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)!
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
