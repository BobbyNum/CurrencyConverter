//
//  NetworkService.swift
//  CurrencyConverterTest
//
//  Created by MyMac on 15/08/2022.
//

import Foundation

protocol NetworkServiceProtocol {
    func getCommisionFee() -> Comission
    func fetchLastBalance() -> [CurrencyBalance]
    func saveLastBalance(balance: [CurrencyBalance])
    func getConversion(amount: String, from: String, to: String, _ completion: @escaping (Result<CurrencyBalance, Error>) -> Void)
}

final class NetworkService: NetworkServiceProtocol {
    static let shared = NetworkService()
    
    enum ConversionFailure: Error {
        case invalidData
        case invalidURL
    }
    
    func getConversion(amount: String, from: String, to: String, _ completion: @escaping (Result<CurrencyBalance, Error>) -> Void) {
        guard let url = URL(string: "http://api.evp.lt/currency/commercial/exchange/\(amount)-\(from)/\(to)/latest") else {
            completion(.failure(ConversionFailure.invalidURL))
            return
        }
        URLSession.shared.dataTask(
                with: url
            ) { data, response, error in
                guard let data = data else {
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.failure(ConversionFailure.invalidData))
                    }
                    return
                }

                let decoder = JSONDecoder()
                let result = Result(catching: {
                    try decoder.decode(CurrencyBalance.self, from: data)
                })
                
                completion(result)
            }
            .resume()
    }
    
    //Mock Data
    func fetchLastBalance() -> [CurrencyBalance] {
        //TODO: will change to real request
        if let currencyBalance = StorageItems.balance, !currencyBalance.isEmpty {
            return currencyBalance
        } else {
            StorageItems.conversionCount = 1
            return [CurrencyBalance(currency: .EUR, amount: "1000.00"),
                    CurrencyBalance(currency: .USD, amount: "0.00"),
                    CurrencyBalance(currency: .JPY, amount: "0.00"),]
        }
    }
    
    func saveLastBalance(balance: [CurrencyBalance]) {
        //TODO: will change to real request
        StorageItems.balance = balance
        let numberOfOperations = StorageItems.conversionCount ?? 0
        StorageItems.conversionCount = numberOfOperations + 1
    }
    
    func getCommisionFee() -> Comission {
        //TODO: will change to real request
        if let count = StorageItems.conversionCount, count > 5 {
            return .regular
        } else {
            return .free
        }
    }
}
