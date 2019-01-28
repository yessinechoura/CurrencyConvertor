//
//  Extentions.swift
//  CurrencyConvertor
//
//  Created by Yessine on 1/28/19.
//  Copyright © 2019 Choura Yessine. All rights reserved.
//

import UIKit

extension CALayer {
    
    func addBorder(edge: UIRectEdge, width: CGFloat, thickness: CGFloat = 0.6, color: UIColor = .black) {
        
        let border = CALayer()
        
        switch edge {
        case .top:
            border.frame = CGRect(x: 0, y: 0, width: width, height: thickness)
        case .bottom:
            border.frame = CGRect(x: 0, y: frame.height - thickness, width: width, height: thickness)
        default:
            break
        }
        
        border.backgroundColor = color.cgColor;
        
        addSublayer(border)
    }
}

extension String {
    
    func isNumeric() -> Bool {
        
        let scanner = Scanner(string: self)
        return scanner.scanDecimal(nil) && scanner.isAtEnd
    }
}

extension UIViewController {
    
    func showSimpleAlert(alertTitle: String = "Warning", alertMessage: String = "Something went wrong, please try again.", actionTitle: String = "Okay") {
        
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alert.setTitle(font: .systemFont(ofSize: 20), color: .black)
        alert.setMessage(font: .systemFont(ofSize: 15, weight: .thin), color: .darkGray)
        alert.addAction(title: actionTitle, color: .black, style: .default, isEnabled: true)
        self.present(alert, animated: true, completion: nil)
    }
}


extension UIAlertController {
    
    func addAction(image: UIImage? = nil, title: String, color: UIColor? = nil, style: UIAlertAction.Style = .default, isEnabled: Bool = true, handler: ((UIAlertAction) -> Void)? = nil) {
        
        let action = UIAlertAction(title: title, style: style, handler: handler)
        action.isEnabled = isEnabled
        
        // button image
        if let image = image {
            action.setValue(image, forKey: "image")
        }
        
        // button title color
        if let color = color {
            action.setValue(color, forKey: "titleTextColor")
        }
        
        addAction(action)
    }
    
    func setTitle(font: UIFont, color: UIColor) {
        guard let title = self.title else { return }
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let attributedTitle = NSMutableAttributedString(string: title, attributes: attributes)
        setValue(attributedTitle, forKey: "attributedTitle")
    }
    
    func set(message: String?, font: UIFont, color: UIColor) {
        if message != nil {
            self.message = message
        }
        setMessage(font: font, color: color)
    }
    
    func setMessage(font: UIFont, color: UIColor) {
        guard let message = self.message else { return }
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let attributedMessage = NSMutableAttributedString(string: message, attributes: attributes)
        setValue(attributedMessage, forKey: "attributedMessage")
    }
}
