//
//  AlertDisplayable.swift
//  CurrencyConverterTest
//
//  Created by MyMac on 15/08/2022.
//

import UIKit

protocol AlertDisplayable: AnyObject {
    func showErrorAlert(with message: String)
    func showAlert(with message: String, title: String)
}

extension AlertDisplayable where Self: UIViewController {
    func showErrorAlert(with message: String) {
        DispatchQueue.main.async {
            self.show(with: message, title: "Warning!", isError: true)
        }
    }
    
    func showAlert(with message: String, title: String) {
        DispatchQueue.main.async {
            self.show(with: message, title: title)
        }
    }
}

private extension AlertDisplayable where Self: UIViewController {
    func show(with message: String, title: String, isError: Bool = false) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: isError ? "OK" : "Done", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
