//
//  StockTableView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

struct StockTableHeaderItem: View {
    @Binding var isShown: Bool
    var description: String
    var stockColumn: StockColumn
    @Binding var sortedStockColumn: StockColumn
    @Binding var sortAscending: Bool
    
    var body: some View {
        if isShown {
            HStack{
                Divider()
                Spacer()
                Text(description).bold()
                if stockColumn == sortedStockColumn {
                    Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                } else {
                    Image(systemName: "arrow.up.arrow.down")
                }
                Spacer()
            }
            .onTapGesture {
                if stockColumn != sortedStockColumn {
                    sortedStockColumn = stockColumn
                    sortAscending = true
                } else { sortAscending.toggle() }
            }
        }
    }
}

struct StockTable: View {
    var filteredStock: Stock
    
    @State private var showTableSettings: Bool = false
    @AppStorage("stockShowProduct") var stockShowProduct: Bool = true
    @AppStorage("stockShowProductGroup") var stockShowProductGroup: Bool = false
    @AppStorage("stockShowAmount") var stockShowAmount: Bool = true
    @AppStorage("stockShowValue") var stockShowValue: Bool = false
    @AppStorage("stockShowNextBestBeforeDate") var stockShowNextBestBeforeDate: Bool = true
    @AppStorage("stockShowCaloriesPerStockQU") var stockShowCaloriesPerStockQU: Bool = false
    @AppStorage("stockShowCalories") var stockShowCalories: Bool = false
    
    @AppStorage("simplifiedStockView") var simplifiedStockView: Bool = false
    
    @State private var sortedStockColumn: StockColumn = .product
    @State private var sortAscending: Bool = true
    
    @Binding var selectedStockElement: StockElement?
    @Binding var activeSheet: StockInteractionSheet?
    @Binding var isShowingSheet: Bool
    
    private func getCaloriesSum(_ stockElement: StockElement) -> Double {
        if let calories = Double(stockElement.product.calories ?? "") {
            let sum = calories * Double(stockElement.amount)!
            return sum
        } else { return 0 }
    }
    
    var sortedStock: Stock {
        filteredStock
            .sorted {
                switch sortedStockColumn {
                case .product:
                    return sortAscending ? ($0.product.name < $1.product.name) : ($0.product.name > $1.product.name)
                case .productGroup:
                    return sortAscending ? ($0.product.productGroupID ?? "" < $1.product.productGroupID ?? "") : ($0.product.productGroupID ?? "" > $1.product.productGroupID ?? "")
                case .amount:
                    return sortAscending ? (Double($0.amountAggregated) ?? 0 < Double($1.amountAggregated) ?? 0) : (Double($0.amountAggregated) ?? 0 > Double($1.amountAggregated) ?? 0)
                case .value:
                    return sortAscending ? (Double($0.value) ?? 0 < Double($1.value) ?? 0) : (Double($0.value) ?? 0 > Double($1.value) ?? 0)
                case .nextBestBeforeDate:
                    return sortAscending ? ($0.bestBeforeDate < $1.bestBeforeDate) : ($0.bestBeforeDate > $1.bestBeforeDate)
                case .caloriesPerStockQU:
                    return sortAscending ? (Double($0.product.calories ?? "") ?? 0 < Double($1.product.calories ?? "") ?? 0) : (Double($0.product.calories ?? "") ?? 0 > Double($1.product.calories ?? "") ?? 0)
                case .calories:
                    return sortAscending ? (getCaloriesSum($0) < getCaloriesSum($1)) : (getCaloriesSum($0) > getCaloriesSum($1))
                }
            }
    }
    
    var shownColumns: Int {
        let shownArray = [stockShowProduct, stockShowProductGroup, stockShowAmount, stockShowValue, stockShowNextBestBeforeDate, stockShowCaloriesPerStockQU, stockShowCalories]
        return shownArray.filter{$0}.count
    }
    
    var columns: [GridItem] {
        let actionHeader = [GridItem(.fixed(180))]
        let columnHeaders = Array(repeating: GridItem(.flexible(minimum: 50), spacing: 0), count: shownColumns)
        return actionHeader + columnHeaders
    }
    
    var body: some View {
        if !simplifiedStockView{
            #if os(macOS)
            contentTable
            #elseif os(iOS)
            //        ScrollView(.horizontal){
            contentTable
            //        }
            #endif
        } else {
            contentSimplified
        }
    }
    
    var contentTable: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            HStack{
                Image(systemName: "eye.fill")
                    .onTapGesture {
                        showTableSettings.toggle()
                    }
                    .popover(isPresented: $showTableSettings, content: {
                        StockTableConfigView(showProduct: $stockShowProduct, showProductGroup: $stockShowProductGroup, showAmount: $stockShowAmount, showValue: $stockShowValue, showNextBestBeforeDate: $stockShowNextBestBeforeDate, showCaloriesPerStockQU: $stockShowCaloriesPerStockQU, showCalories: $stockShowCalories)
                            .padding()
                            .frame(minWidth: 300, minHeight: 400, alignment: .center)
                    })
                Spacer()
            }
            StockTableHeaderItem(isShown: $stockShowProduct, description: "str.stock.tbl.product".localized, stockColumn: .product, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
            StockTableHeaderItem(isShown: $stockShowProductGroup, description: "str.stock.tbl.productGroup".localized, stockColumn: .productGroup, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
            StockTableHeaderItem(isShown: $stockShowAmount, description: "str.stock.tbl.amount".localized, stockColumn: .amount, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
            StockTableHeaderItem(isShown: $stockShowValue, description: "str.stock.tbl.value".localized, stockColumn: .value, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
            StockTableHeaderItem(isShown: $stockShowNextBestBeforeDate, description: "str.stock.tbl.nextBestBefore".localized, stockColumn: .nextBestBeforeDate, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
            StockTableHeaderItem(isShown: $stockShowCaloriesPerStockQU, description: "str.stock.tbl.caloriesPerStockQU".localized, stockColumn: .caloriesPerStockQU, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
            StockTableHeaderItem(isShown: $stockShowCalories, description: "str.stock.tbl.calories".localized, stockColumn: .calories, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
            ForEach(sortedStock, id:\.productID) { stockElement in
                StockTableRow(showProduct: $stockShowProduct, showProductGroup: $stockShowProductGroup, showAmount: $stockShowAmount, showValue: $stockShowValue, showNextBestBeforeDate: $stockShowNextBestBeforeDate, showCaloriesPerStockQU: $stockShowCaloriesPerStockQU, showCalories: $stockShowCalories, stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, isShowingSheet: $isShowingSheet)
            }
        }
        .padding(.horizontal)
        .animation(.default)
    }
    
    var contentSimplified: some View {
        VStack() {
            ForEach(sortedStock, id:\.productID) { stockElement in
                StockTableRowSimplified(stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, isShowingSheet: $isShowingSheet)
            }
        }
    }
}

//struct StockTable_Previews: PreviewProvider {
//    static var previews: some View {
//        StockTable(filteredStock: [                            StockElement(amount: "3", amountAggregated: "3", value: "25", bestBeforeDate: "2020-12-12", amountOpened: "1", amountOpenedAggregated: "1", isAggregatedAmount: "0", dueType: "1", productID: "3", product: MDProduct(id: "3", name: "Productname", mdProductDescription: "Description", productGroupID: "1", active: "1", locationID: "1", shoppingLocationID: "1", quIDPurchase: "1", quIDStock: "1", quFactorPurchaseToStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "1", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1233", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "ts", userfields: nil))])
//    }
//}
