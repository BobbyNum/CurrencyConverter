//
//  ViewController.swift
//  CurrencyConverterTest
//
//  Created by MyMac on 15/08/2022.
//

import UIKit
import DropDown
import IQKeyboardManagerSwift

class ViewController: UIViewController, AlertDisplayable, IQKeyboardManagable {
    
    @IBOutlet weak var balanceCollectionView: UICollectionView!
    @IBOutlet weak var sellCurrencyMenu: UIButton!
    @IBOutlet weak var sellTextField: UITextField!
    @IBOutlet weak var receiveCurrencyMenu: UIButton!
    @IBOutlet weak var receiveCurrencyLabel: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    
    private var currencyViewModel: CurrencyViewModel?
    private let dropDownSell = DropDown()
    private let dropDownReceive = DropDown()
    
    private var currentSellCurrency: Currency = .EUR
    private var currentReceiveCurrency: Currency = .USD
    
    //MARK: - Initialization and Setup UI
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sellTextField.becomeFirstResponder()
    }
    
    private func setupUI() {
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        
        submitButton.layer.cornerRadius = 30
        submitButton.clipsToBounds = true
        
        sellTextField.delegate = self
        sellTextField.text = "0.00"
        
        setupChooseCurrencyMenu()
    }
    
    private func configureCollectionView() {
        currencyViewModel = CurrencyViewModel(collectionView: balanceCollectionView,
                                              superview: view)
        balanceCollectionView.dataSource = currencyViewModel
        balanceCollectionView.layoutIfNeeded()
    }
    
    //MARK: - private
    private func setupChooseCurrencyMenu() {
        guard let model = currencyViewModel else {return}
        DropDown.startListeningToKeyboard()
        dropDownSell.anchorView = sellCurrencyMenu
        dropDownSell.dataSource = model.getAllCurrenciesInString()
        dropDownSell.selectionAction = { [unowned self] (index: Int, item: String) in
            self.sellCurrencyMenu.setTitle(item, for: .normal)
            currentSellCurrency = Currency(rawValue: item) ?? .EUR
            
            dropDownReceive.dataSource = model.getAllCurrenciesInString(excludeCurrency: currentSellCurrency)
            if currentSellCurrency == currentReceiveCurrency {
                self.setReceiveCurrencyDropDownMenu(item: dropDownReceive.dataSource[0])
            }
            updateReceiveValue()
        }
        
        dropDownReceive.anchorView = receiveCurrencyMenu
        dropDownReceive.dataSource = model.getAllCurrenciesInString(excludeCurrency: currentSellCurrency)
        dropDownReceive.selectionAction = { [unowned self] (index: Int, item: String) in
            self.setReceiveCurrencyDropDownMenu(item: item)
            updateReceiveValue()
        }
    }
    
    private func setReceiveCurrencyDropDownMenu(item: String) {
        self.receiveCurrencyMenu.setTitle(item, for: .normal)
        currentReceiveCurrency = Currency(rawValue: item) ?? .USD
    }
    
    private func updateReceiveValue() {
        guard let amount = self.sellTextField.text, !amount.isEmpty && Decimal(string: amount) != 0.0 else {
            receiveCurrencyLabel.text = "0.00"
            return
        }
        if let model = currencyViewModel {
            model.updateReceiveValue(amount: amount, from: currentSellCurrency, to: currentReceiveCurrency) { [unowned self] receiveAmount in
                receiveCurrencyLabel.text = "+ " + receiveAmount
                receiveCurrencyLabel.textColor = AppConstants.systemGreenColor
            }
        }
    }
    
    private func clearCurrencyLabels() {
        sellTextField.text = "0.00"
        receiveCurrencyLabel.text = "0.00"
        receiveCurrencyLabel.textColor = .black
    }
    
    
    //MARK: - Actions
    @IBAction func chooseSellCurrencyAction(_ sender: Any) {
        self.view.endEditing(true)
        dropDownSell.show()
    }
    
    @IBAction func chooseReceiveCurrencyAction(_ sender: Any) {
        self.view.endEditing(true)
        dropDownReceive.show()
    }
    
    @IBAction func submitAction(_ sender: Any) {
        self.view.endEditing(true)
        if let model = currencyViewModel, let sellCurrencyAmount = sellTextField.text {
            if let error = model.validateConversion(for: sellCurrencyAmount, currency: currentSellCurrency) {
                self.showErrorAlert(with: error)
                self.clearCurrencyLabels()
                return
            }
            
            model.convertCurrency(amount: sellCurrencyAmount, from: currentSellCurrency, to: currentReceiveCurrency) { [unowned self] result in
                switch result {
                case .success(let resultConverse):
                    DispatchQueue.main.async {
                        self.showAlert(with: "You have converted \(sellCurrencyAmount) \(self.currentSellCurrency) to \(resultConverse.amount) \(resultConverse.currency). Commission Fee - \(String(format: "%.2f", Double(truncating: model.getComissionFee(for: sellCurrencyAmount) as NSNumber))) \(self.currentSellCurrency).", title: "Currency converted")
                        model.updateCurrentBalance(amount: sellCurrencyAmount, from: self.currentSellCurrency, to: resultConverse.currency, result: resultConverse.amount)
                        
                        self.clearCurrencyLabels()
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        print("Error of Conversion \(error)")
                        self.showErrorAlert(with: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    var amountTypedString = ""
}

//MARK: - UITextFieldDelegate
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        amountTypedString = ""
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        self.updateReceiveValue()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.sellTextField, ((self.sellTextField.text?.count ?? 0) + string.count) >= 10  {
            return false
        }
        
        if string.count > 0 {
            if amountTypedString == ""{
                textField.text = " "
            }
            amountTypedString += string
            textField.text = amountTypedString + ".00"
        } else {
            amountTypedString = String(amountTypedString.dropLast())
            if amountTypedString.count > 0 {
                textField.text = amountTypedString + ".00"
            } else {
                clearCurrencyLabels()
            }
        }
        return false
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        amountTypedString = ""
        return true
    }
}




