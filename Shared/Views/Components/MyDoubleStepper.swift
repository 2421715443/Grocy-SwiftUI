//
//  MyDoubleStepper.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MyDoubleStepper: View {
    @Binding var amount: Double?
    
    var description: String
    var descriptionInfo: String?
    var minAmount: Double? = 0.0
    var amountStep: Double? = 1.0
    var amountName: String? = nil
    
    var errorMessage: String?
    
    var systemImage: String?
    
    var currencySymbol: String?
    
    var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.allowsFloats = true
        if let currencySymbol = currencySymbol {
            f.numberStyle = .currency
            f.isLenient = true
            f.currencySymbol = currencySymbol
        } else {
            f.numberStyle = .decimal
        }
        f.maximumFractionDigits = 4
        return f
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1){
            HStack{
                Text(LocalizedStringKey(description))
                if let descriptionU = descriptionInfo {
                    FieldDescription(description: descriptionU)
                }
            }
            HStack{
                if systemImage != nil {
                    Image(systemName: systemImage!)
                }
                #if os(iOS)
                TextField("", value: $amount, formatter: formatter)
                    .frame(width: 70)
                    .keyboardType(.numberPad)
                #else
                TextField("", value: $amount, formatter: formatter)
                    .frame(width: 70)
                #endif
                Stepper(LocalizedStringKey(amountName ?? ""), onIncrement: {
                    if amount != nil {
                        amount! += amountStep ?? 1.0
                    } else { amount = amountStep }
                }, onDecrement: {
                    if amount != nil {
                        if minAmount != nil {
                            if amount! > minAmount! {
                                amount! -= amountStep ?? 1.0
                            }
                        } else { amount! -= amountStep ?? 1.0 }
                    } else { amount = 0 }
                })
            }
            if minAmount != nil {
                if let amount = amount {
                    if amount < minAmount! {
                        if errorMessage != nil {
                            Text(LocalizedStringKey(errorMessage!))
                                .font(.caption)
                                .foregroundColor(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }
}

struct MyDoubleStepper_Previews: PreviewProvider {
    static var previews: some View {
        MyDoubleStepper(amount: Binding.constant(0), description: "Description", descriptionInfo: "Description info Text", minAmount: 1.0, amountStep: 0.1, amountName: "QuantityUnit", errorMessage: "Error in inputsadksaklwkfleksfklmelsfmlklkmlmgkelsmkgmlemkl", systemImage: "tag")
            .padding()
    }
}
