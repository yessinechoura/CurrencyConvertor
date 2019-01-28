//
//  GlobalStructs.swift
//  CurrencyConvertor
//
//  Created by Yessine on 1/27/19.
//  Copyright © 2019 Choura Yessine. All rights reserved.
//

import Foundation

struct OpenExchangeRatesWebService {
    
    static let appId = "1ef216b49f7048a5a08549fbdec6cb2c"
    static let appIdParam = "app_id"
    
    static let baseUrl = "https://openexchangerates.org"
    static let fetchCurrencyRates = "/api/latest.json"
}
