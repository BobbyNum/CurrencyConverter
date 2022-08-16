//
//  IQKeyboardManagable.swift
//  CurrencyConverterTest
//
//  Created by MyMac on 16/08/2022.
//

import IQKeyboardManagerSwift

protocol IQKeyboardManagable {
    func enableKeyboard(_ enable: Bool)
}

extension IQKeyboardManagable {
    func enableKeyboard(_ enable: Bool) {
        IQKeyboardManager.shared.enable = enable
    }
}
