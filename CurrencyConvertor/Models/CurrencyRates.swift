//
//  CurrencyRates.swift
//  CurrencyConvertor
//
//  Created by Yessine on 1/27/19.
//  Copyright © 2019 Choura Yessine. All rights reserved.
//

import Foundation

struct CurrencyRates: Decodable {
    
    let disclaimer: String?
    let license: String?
    let timestamp: Int
    let base: String?
    let rates: [String : Float]
}
