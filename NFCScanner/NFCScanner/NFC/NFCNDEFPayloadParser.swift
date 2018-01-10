//
//  NFCNDEFPayloadParser.swift
//  NFCScanner
//
//  Created by Himanshu Tantia on 4/1/18.
//  Copyright © 2018 Kreativ Apps, LLC. All rights reserved.
//

import Foundation
import CoreNFC

extension NFCNDEFPayload {
    
    func parse() -> NDEFPayload? {
        guard let payloadType = NDEFHeader.PayloadType(withData: self.type) else { return nil }
        guard let typeString =  String(data: self.type, encoding: .utf8) else { return nil }
        guard let identifierString = String(data: self.identifier, encoding: .utf8) else { return nil }
        print(typeString)
        print(identifierString)
        print(payloadType)
        
        let payloadBytes = Array(self.payload)
        
        switch self.typeNameFormat {
        case .nfcWellKnown:
            switch payloadType {
            case .text:
                return parseText(payload: payloadBytes)
            case .uri:
                return parseURI(payload: payloadBytes)
            case .smartPoster:
                return parseSmartPoster(payload: payloadBytes) //parse smart poseter payload
            default:
                return nil
            }
        case .media:
            switch payloadType {
            case .vCard:
                return parseVCard(payload: payloadBytes) //parse vCard payload
            case .wifi:
                return parseWifi(payload: payloadBytes) //parse wifi payload
            default:
                return nil
            }
        case .empty:
            return nil
        case .absoluteURI:
            return nil
        case .nfcExternal:
            return nil
        case .unknown:
            return nil
        case .unchanged:
            return nil
        }
    }
}

private extension NFCNDEFPayload {
    
    func parseText(payload bytes : [UInt8]) -> NDEFTextPayload? {
        if bytes.isEmpty { return nil }
        let statusByte = bytes[0]
        let __bits = bits(fromByte: statusByte)
        let __isUTF16 = __bits[7]
        let __langCodeLen = Int(statusByte & 0x7F)
        let remainingBytes = bytes.dropFirst()
        let __langCodeBytes = remainingBytes.dropLast(remainingBytes.count-__langCodeLen)
        let __textBytes = remainingBytes.dropFirst(__langCodeLen)
        let langCode = String(bytes: __langCodeBytes, encoding: .utf8) ?? ""
        let encoding: String.Encoding
        let text: String
        if __isUTF16 == .one {
            encoding = .utf16
            text = String(bytes: __textBytes, encoding: encoding) ?? ""
        } else {
            encoding = .utf8
            text = String(bytes: __textBytes, encoding: encoding) ?? ""
        }
        return NDEFTextPayload(utf: encoding, langCode: langCode, text: text)
    }
    
    func parseURI(payload bytes : [UInt8]) -> NDEFURIPayload? {
        if bytes.isEmpty { return nil }
        var remainingBytes = bytes
        let idCode = remainingBytes.removeFirst()
        let scheme = NDEFURIPayload.IDCode(rawValue: idCode)
        let host = String(bytes: remainingBytes, encoding: .utf8) ?? ""
        return NDEFURIPayload(idCode: scheme ?? .unknown, host: host)
    }
    
    func parseSmartPoster(payload bytes : [UInt8]) -> NDEFSmartPosterPayload? {
        var uriPayload: NDEFURIPayload?
        var texts = [String]()
        
        var remainingBytes = bytes
        var header = parseHeader(payload: remainingBytes)
        while (header != nil) {
            remainingBytes.removeFirst(remainingBytes.count - header!.payloadOffset)
            
            let bytes = remainingBytes.dropLast(remainingBytes.count - header!.payloadLength)
            if header?.type == .uri {
                uriPayload = parseURI(payload: Array(bytes))
            } else if header?.type == .text {
                if let payload = parseText(payload: Array(bytes)) {
                    texts.append(payload.text)
                }
            }
            remainingBytes.removeFirst(header!.payloadLength)
            
            header = parseHeader(payload: remainingBytes)
            
            if remainingBytes.isEmpty {
                break
            }
        }
        let smart = NDEFSmartPosterPayload(uri: uriPayload!, payloadTexts: texts)
        return smart
    }
    
    func parseVCard(payload bytes : [UInt8]) -> NDEFTextXVCardPayload? {
        let text = String(bytes: bytes, encoding: .utf8) ?? ""
        return NDEFTextXVCardPayload(text: text)
    }
    
    func parseWifi(payload bytes : [UInt8]) -> NDEFWifiSimpleConfigPayload? {
        
        return nil
    }
}

private extension NFCNDEFPayload {
    func parseHeader(payload bytes : [UInt8]) -> NDEFHeader? {
        if bytes.isEmpty {
            return nil
        }
        var remainingBytes = bytes
        let statusByte = remainingBytes.removeFirst()
        
        let _statusByte = NDEFHeader.StatusByte(withStatusByte: statusByte)
        let _typeLen = remainingBytes.removeFirst()
        let typeLen = Int(_typeLen)
        
        let payloadLen: Int
        if _statusByte.recordIsContainedInOneMessage {
            let _payloadLen = remainingBytes.removeFirst()
            payloadLen = Int(_payloadLen)
        } else {
            let len = remainingBytes.dropLast(remainingBytes.count - 4)
            if let lenStr = String(bytes: len, encoding: .utf8) {
                payloadLen = Int(lenStr) ?? 0
            } else {
                payloadLen = 0
            }
            remainingBytes.removeFirst(4)
        }
        
        var idLen: Int = 0
        var ID: UInt8 = 0
        if _statusByte.idFieldIsPresent &&
            !remainingBytes.isEmpty {
            idLen = Int(remainingBytes.removeFirst())
        }
        
        var typeString : String = ""
        if remainingBytes.count > typeLen {
            let typeBytes = remainingBytes.dropLast(remainingBytes.count - typeLen)
            typeString = String(bytes: typeBytes, encoding: .utf8) ?? ""
            print(typeString)
            remainingBytes.removeFirst(typeLen)
        }
        
        if _statusByte.idFieldIsPresent && idLen > 0 {
            let idBytes = remainingBytes.dropLast(remainingBytes.count - idLen)
            if let d = idBytes.first {
                ID = d
            }
            remainingBytes.removeFirst(idLen)
        }
        
        let _type = NDEFHeader.PayloadType(rawValue: typeString) ?? .unknown
        
        let header: NDEFHeader = NDEFHeader(statusByte: _statusByte, type: _type, identifer: ID, payloadLength: payloadLen, payloadOffset: remainingBytes.count)
        return header
    }
}

func bits(fromByte byte: UInt8) -> [Bit] {
    var byte = byte
    var bits = [Bit](repeating: .zero, count: 8)
    for i in 0..<8 {
        let currentBit = byte & 0x01
        if currentBit != 0 {
            bits[i] = .one
        }
        byte >>= 1
    }
    return bits
}

func bytes(fromBits bits: [Bit]) -> [UInt8] {
    assert(bits.count % 8 == 0, "Bit array size must be multiple of 8")
    
    let numBytes = 1 + (bits.count - 1) / 8
    var bytes = [UInt8](repeating: 0, count: numBytes)
    
    for (index, bit) in bits.enumerated() {
        if bit == .one {
            bytes[index / 8] += UInt8(1 << (7 - index % 8))
        }
    }
    return bytes
}

enum Bit: UInt8, CustomStringConvertible {
    case zero, one
    
    var description: String {
        switch self {
        case .one:
            return "1"
        case .zero:
            return "0"
        }
    }
}
