//
//  CurrencyViewModel.swift
//  CurrencyConverterTest
//
//  Created by MyMac on 15/08/2022.
//

import UIKit

final class CurrencyViewModel: NSObject {
    private weak var collectionView: UICollectionView!
    private weak var superview: UIView!
    
    private(set) var dataSource: [CurrencyBalance]?
    private var networkService: NetworkServiceProtocol = NetworkService.shared
    
    //MARK: - Init
    init(collectionView: UICollectionView, superview: UIView) {
        self.dataSource = networkService.fetchLastBalance()
        self.collectionView = collectionView
        
        self.superview = superview
        super.init()
    }
    
    //MARK: - Private
    private func update() {
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }
    
    private func getValueForCurrency(_ currency: Currency) -> String? {
        guard let dataSource = dataSource,
              let amount = dataSource.filter({ $0.currency == currency}).first?.amount else { return nil}
        return amount
    }
    
    private func isValidateSumForExchange(amountString: String, currency: Currency) -> Bool {
        guard let totalAmountString = getValueForCurrency(currency), totalAmountString != "", let totalAmount = Decimal(string: totalAmountString), let amount = Decimal(string: amountString) else {return false}
        return (totalAmount - getComissionFee(for: amountString)) >= amount
        
    }
    
    //Comission
    func getComissionFee(for amount: String) -> Decimal {
        return (Decimal(string: amount) ?? 0.0) * networkService.getCommisionFee().rawValue/100
    }
    
    
    //Validation
    func validateConversion(for amountString: String, currency: Currency) -> String? {
        if (Decimal(string: amountString) ?? 0.0) <= 0.0 {
            return AppConstants.zeroError
        } else if !isValidateSumForExchange(amountString: amountString, currency: currency) {
            return AppConstants.notEnoughError
        } else {
            return nil
        }
    }
    
    
    //Convert currency
    func convertCurrency(amount: String, from: Currency, to: Currency, _ completion: @escaping (Result<CurrencyBalance, Error>) -> Void) {
        networkService.getConversion(amount: amount, from: from.rawValue, to: to.rawValue) { result in
            completion(result)
        }
    }
    
    func updateReceiveValue(amount: String, from: Currency, to: Currency, _ completion: @escaping (String) -> Void) {
        let group = DispatchGroup()
        group.enter()
        convertCurrency(amount: amount, from: from, to: to) { result in
            switch result {
            case .success(let resultConverse):
                DispatchQueue.main.async {
                    completion(resultConverse.amount)
                }
            case .failure(let error):
                print("Error of Conversion \(error)")
            }
            group.leave()
        }
        group.wait()
    }
    
    func getAllCurrenciesInString(excludeCurrency: Currency? = nil) -> [String] {
        let listCurrencies = Currency.allCases
        return excludeCurrency != nil ? listCurrencies.filter{$0 != excludeCurrency!}.compactMap { $0.rawValue } : listCurrencies.compactMap { $0.rawValue }
    }
    
    func updateCurrentBalance(amount: String, from: Currency, to: Currency, result: String) {
        dataSource?.indices.forEach({ index in
            //update sell currency
            if dataSource?[index].currency == from {
                let totalAmount: Decimal = Decimal(string: dataSource?[index].amount ?? "0.0") ?? 0.0
                let newValue = totalAmount - (Decimal(string: amount) ?? 0.0) - getComissionFee(for: amount)
                dataSource?[index].amount = String(format: "%.2f", Double(truncating: newValue as NSNumber))
            }
            
            //update receive currency
            if dataSource?[index].currency == to {
                let totalAmount: Decimal = Decimal(string: dataSource?[index].amount ?? "0.0") ?? 0.0
                let newValue = totalAmount + (Decimal(string: result) ?? 0.0)
                dataSource?[index].amount = String(format: "%.2f", Double(truncating: newValue as NSNumber))
            }
        })
        if let newBalance = dataSource {
            networkService.saveLastBalance(balance: newBalance)
        }
        self.update()
    }
}

//MARK: - UICollectionViewDataSource
extension CurrencyViewModel: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return dataSource?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: BalanceCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! BalanceCollectionViewCell
        if let item = dataSource?[indexPath.row] {
            cell.titleLabel.text = "\(item.amount) " + item.currency.rawValue
        }
        return cell
    }
}
