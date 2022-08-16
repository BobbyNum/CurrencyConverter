//
//  MockStorage.swift
//  CurrencyConverterTest
//
//  Created by MyMac on 15/08/2022.
//

import Foundation

enum StorageItems {
    @UserDefault(key: "balance", initialValue: [CurrencyBalance]()) static var balance: [CurrencyBalance]?
    @UserDefault(key: "conversionCount", initialValue: Int()) static var conversionCount: Int?
}

@propertyWrapper
struct UserDefault<T: Codable> {
    var key: String
    var initialValue: T
    var wrappedValue: T? {
        set { saveData(newValue, key: key) }
        get { getData(key: key) }
    }
    
    func getData<T: Decodable>(key: String) -> T? {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(T.self, from: data){
            return decoded
        } else {
            return nil
        }
    }
    
    func saveData<T: Encodable>(_ item: T, key: String) {
        if let encoded = try? JSONEncoder().encode(item) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}



