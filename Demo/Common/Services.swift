//
//  Services.swift
//  OAuthSwift

//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Foundation

// Class which contains services parameters like consumer key and secret
typealias ServicesValue = String

class Services {
    var parameters : [String: [String: ServicesValue]]
    
    init() {
       self.parameters = [:]
    }
    
    subscript(service: String) -> [String:ServicesValue]? {
        get {
            return parameters[service]
        }
        set {
            if let value = newValue , !Services.parametersEmpty(value) {
                parameters[service] = value
            }
        }
    }
    
    func loadFromFile(_ path: String) {
        if let newParameters = NSDictionary(contentsOfFile: path) as? [String: [String: ServicesValue]] {
         
            for (service, dico) in newParameters {
                if parameters[service] != nil && Services.parametersEmpty(dico) { // no value to set
                    continue
                }
                updateService(service, dico: dico)
            }
        }
    }

    func updateService(_ service: String, dico: [String: ServicesValue]) {
        var resultdico = dico
        if let oldDico = self.parameters[service] {
            resultdico = oldDico
            resultdico += dico
        }
        self.parameters[service] = resultdico
    }
    
    static func parametersEmpty(_ dico: [String: ServicesValue]) -> Bool {
       return  Array(dico.values).filter({ (p) -> Bool in !p.isEmpty }).isEmpty
    }

    var keys: [String] {
        return Array(self.parameters.keys).sorted()
    }
}

func += <KeyType, ValueType> (left: inout Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}
