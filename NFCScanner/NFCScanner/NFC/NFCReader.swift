//
//  NFCReader.swift
//  NFCScanner
//
//  Created by Himanshu Tantia on 10/1/18.
//  Copyright © 2018 Kreativ Apps, LLC. All rights reserved.
//

import UIKit
import CoreNFC

protocol NFCReaderDelegate :class {
    func reader(NFCReader: NFCReader, didInvalidateWithError error: Error)
    func reader(NFCReader: NFCReader, didDetectPayloads messages: [NDEFPayload])
}

extension NFCTypeNameFormat : CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .absoluteURI:
            return "absoluteURI (\(self.rawValue))"
        case .empty:
            return "empty (\(self.rawValue))"
        case .media:
            return "absoluteURI (\(self.rawValue))"
        case .nfcExternal:
            return "nfcExternal (\(self.rawValue))"
        case .nfcWellKnown:
            return "nfcWellKnown (\(self.rawValue))"
        case .unchanged:
            return "unchanged (\(self.rawValue))"
        case .unknown:
            return "unknown (\(self.rawValue)) "
        }
    }
}

class NFCReader : NSObject {
    
    class var isAvailable:  Bool {
        if #available(iOS 11.0, *) {
            return NFCNDEFReaderSession.readingAvailable
        }
        return false
    }
    
    private let delegateQueue = DispatchQueue(label: "com.kreativapps.NFCKit.NFCReader-delegate_callback_DispatchQueue")
    private weak var presentingController: UIViewController?
    private weak var delegate: NFCReaderDelegate?
    
    init(withController controller: UIViewController? = nil, andDelegate delegate: NFCReaderDelegate? = nil) {
        super.init()
        self.presentingController  = controller
        self.delegate = delegate
    }
    
    func start() {
        if #available(iOS 11.0, *) {
            let session = NFCNDEFReaderSession(delegate: self, queue: delegateQueue, invalidateAfterFirstRead: false)
            session.alertMessage = "Bring your card to the top of the phone to scan it"
            session.begin()
        } else  {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "NFC Reader Unavailable", message: "NFC Reading capabilities are available on devices, iPhone 7 or above,  running iOS 11 or greater", preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .default, handler: { alertAction in
                    self.delegate?.reader(NFCReader: self, didInvalidateWithError: NFCReaderError.readerErrorUnsupportedFeature as! Error)
                })
                alert.addAction(action)
            }
        }
    }
}

@available(iOS 11.0, *)
extension NFCReader : NFCNDEFReaderSessionDelegate {
    
    func readerSession(_ NFCNDEFReaderSession: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        let err = error as NSError
        DispatchQueue.main.async {
            let alert = UIAlertController(title: err.domain, message: err.localizedDescription, preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: { alertAction in
                self.delegate?.reader(NFCReader: self, didInvalidateWithError: error)
            })
            alert.addAction(action)
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        var result = [NDEFPayload]()
        for idx in 0...messages.count-1 {
            for record in messages[idx].records {
                if let p = record.parse() {
                    result.append(p)
                }
            }
        }
        delegate?.reader(NFCReader: self, didDetectPayloads: result)
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "didDetectNDEFs", message: "\(result.count)", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: { alertAction in
                self.delegate?.reader(NFCReader: self, didDetectPayloads: result)
            })
            alert.addAction(action)
            self.presentingController?.present(alert, animated: true, completion: {
                print(result)
            })
        }
    }
}
