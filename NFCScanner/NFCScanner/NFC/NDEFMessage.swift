//
//  NDEFMessage.swift
//  NFCScanner
//
//  Created by Himanshu Tantia on 3/1/18.
//  Copyright © 2018 Kreativ Apps, LLC. All rights reserved.
//

import Foundation
import CoreNFC

struct NDEFMessage {
    let header: NDEFHeader
    let payload: NDEFPayload
}

struct NDEFHeader {
    
    struct StatusByte {
        let mb : Bit
        let me : Bit
        let cf : Bit
        let sr : Bit
        let il : Bit
        let tfn : NFCTypeNameFormat
        
        var idFieldIsPresent : Bool {
            return (il == .one)
        }
        var recordIsChunkedUpAcrossMultipleMessages : Bool {
            return (cf == .one)
        }
        var recordIsContainedInOneMessage : Bool {
            return (sr == .one)
        }
        
        init(withStatusByte byte: UInt8) {
            let _bits = bits(fromByte: byte)
            mb = _bits[7]
            me = _bits[6]
            cf = _bits[5]
            sr = _bits[4]
            il = _bits[3]
            tfn = NFCTypeNameFormat(rawValue: byte & 0x07) ?? .unknown
        }
    }
    
    enum PayloadType : String {
        case text = "T"
        case uri = "U"
        case smartPoster = "Sp"
        case vCard = "text/x-vCard"
        case wifi = "application/vnd.wfa.wsc"
        case unknown
        
        init? (withData data: Data) {
            guard let typeString = String(data: data, encoding: .utf8) else { return nil }
            self.init(rawValue: typeString)
        }
    }
    let statusByte: StatusByte
    let type: PayloadType
    let identifer: UInt8
    let payloadLength: Int
    let payloadOffset: Int // Length of parsed bytes before payload
}

protocol NDEFPayload {
    
}

protocol NDEFWellKnownPayload : NDEFPayload {
    
}

protocol NDEFMediaPayload : NDEFPayload {
    
}

struct NDEFTextPayload : NDEFWellKnownPayload {
    let utf: String.Encoding
    let langCode: String
    let text: String
    var isUTF16: Bool {
        return utf == .utf16
    }
}

struct NDEFURIPayload : NDEFWellKnownPayload {
    
    enum IDCode : UInt8 {
        case none = 0x00
        case www = 0x01
        case swww = 0x02
        case http = 0x03
        case https = 0x04
        case tel = 0x05
        case email = 0x06
        case ftpanonym = 0x07
        case ftp_ftp = 0x08
        case ftps = 0x09
        case sftp = 0x0A
        case smb = 0x0B
        case nfs = 0x0C
        case ftp = 0x0D
        case dav = 0x0E
        case news = 0x0F
        case telnet = 0x10
        case imap = 0x11
        case stsp = 0x12
        case urn = 0x13
        case pop = 0x14
        case sip = 0x15
        case sips = 0x16
        case tftp = 0x17
        case btspp = 0x18
        case btl2cap = 0x19
        case btgoep = 0x1A
        case tcpobex = 0x1B
        case irdaobex = 0x1C
        case file = 0x1D
        case urn_epc_id = 0x1E
        case urn_epc_tag = 0x1F
        case urn_epc_pat = 0x20
        case urn_epc_raw = 0x21
        case urn_epc = 0x22
        case urn_nfc = 0x23
        case rfu //0x24...0xFF //RFU Reserved for Future Use, Not Valid Inputs
        case unknown
        
        var scheme: String {
            switch self {
            case .none:
                return ""
            case .www:
                return "http://www."
            case .swww:
                return "https://www."
            case .http:
                return "http://"
            case .https:
                return "https://"
            case .tel:
                return "tel:"
            case .email:
                return "mailto:"
            case .ftpanonym:
                return "ftp://anonymous:anonymous@"
            case .ftp_ftp:
                return "ftp://ftp."
            case .ftps:
                return "ftps://"
            case .sftp:
                return "sftp://"
            case .smb:
                return "smb://"
            case .nfs:
                return "nfs://"
            case .ftp:
                return "ftp://"
            case .dav:
                return "dav://"
            case .news:
                return "news:"
            case .telnet:
                return "telnet://"
            case .imap:
                return "imap:"
            case .stsp:
                return "rtsp://"
            case .urn:
                return "urn:"
            case .pop:
                return "pop:"
            case .sip:
                return "sip:"
            case .sips:
                return "sips:"
            case .tftp:
                return "tftp:"
            case .btspp:
                return "btspp://"
            case .btl2cap:
                return "btl2cap://"
            case .btgoep:
                return "btgoep://"
            case .tcpobex:
                return "tcpobex://"
            case .irdaobex:
                return "irdaobex://"
            case .file:
                return "file://"
            case .urn_epc_id:
                return "urn:epc:id:"
            case .urn_epc_tag:
                return "urn:epc:tag:"
            case .urn_epc_pat:
                return "urn:epc:pat:"
            case .urn_epc_raw:
                return "urn:epc:raw:"
            case .urn_epc:
                return "urn:epc:"
            case .urn_nfc:
                return "urn:nfc:"
            case .rfu:
                return ""
            case .unknown:
                return ""
            }
        }
        
        init(withByte byte: UInt8) {
            if let id = IDCode(rawValue: byte) {
                self = id
            } else if case 0x24...0xFF = byte {
                self = .rfu
            } else {
                self = .unknown
            }
        }
    }
    
    let idCode:IDCode
    let host: String
    
    var uri: URL? {
        return URL(string: idCode.scheme + host)
    }
}

struct NDEFSmartPosterPayload : NDEFWellKnownPayload {
    let uri: NDEFURIPayload
    let payloadTexts: [String]
}

struct NDEFTextXVCardPayload : NDEFMediaPayload {
    let text: String
}

struct NDEFWifiSimpleConfigPayload : NDEFMediaPayload {
    let credentials: [NDEFWifiSimpleConfigCredential]
    let version2: NDEFWifiSimpleConfigVersion2
}

struct NDEFWifiSimpleConfigCredential {
    
    enum Security : UInt8 {
        case open = 0x00
        case wpaPersonal = 0x01
        case shared = 0x02
        case wpaEnterprise = 0x03
        case wpa2Enterprise = 0x04
        case wpa2Personal = 0x05
        case wpaWpa2Personal = 0x06
        
        var displayLabel: String {
            switch self {
            case .open:
                return "Open"
            case .wpaPersonal:
                return "WPA Personal"
            case .shared:
                return "Shared"
            case .wpaEnterprise:
                return "WPA Enterprise"
            case .wpa2Enterprise:
                return "WPA2 Enterprise"
            case .wpa2Personal:
                return "WPA2 Personal"
            case .wpaWpa2Personal:
                return "WPA/WPA2 Personal"
            }
        }
    }
    
    enum Encryption : UInt8 {
        case none = 0x00
        case wep = 0x01
        case tkip = 0x02
        case aes = 0x03
        case aesTkip = 0x04
        
        var displayLabel: String {
            switch self {
            case .none:
                return "None"
            case .wep:
                return "WEP"
            case .tkip:
                return "TKIP"
            case .aes:
                return "AES"
            case .aesTkip:
                return "AES/TKIP"
            }
        }
    }

    let ssid: String
    let macAddress: String
    let networIndex: UInt8
    let networkKey: String
    let authType: Security
    let encryptType: Encryption
}

struct NDEFWifiSimpleConfigVersion2 {
    let version: String
}
