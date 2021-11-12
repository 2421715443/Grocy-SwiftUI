//
//  MDProductsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDProductRowView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var product: MDProduct
    
    var body: some View {
        HStack{
            if let pictureFileName = product.pictureFileName, !pictureFileName.isEmpty, let base64Encoded = pictureFileName.data(using: .utf8)?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)), let pictureURL = grocyVM.getPictureURL(groupName: "productpictures", fileName: base64Encoded), let url = URL(string: pictureURL) {
                AsyncImage(url: url, content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color.white)
                }, placeholder: {
                    ProgressView()
                })
                    .frame(width: 75, height: 75)
            }
            VStack(alignment: .leading) {
                Text(product.name).font(.title)
                HStack(alignment: .top){
                    if let locationID = GrocyViewModel.shared.mdLocations.firstIndex { $0.id == product.locationID } {
                        Text(LocalizedStringKey("str.md.product.rowLocation \(grocyVM.mdLocations[locationID].name)"))
                            .font(.caption)
                    }
                    if let productGroup = GrocyViewModel.shared.mdProductGroups.firstIndex { $0.id == product.productGroupID } {
                        Text(LocalizedStringKey("str.md.product.rowProductGroup \(grocyVM.mdProductGroups[productGroup].name)"))
                            .font(.caption)
                    }
                }
                if let description = product.mdProductDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .italic()
                }
            }
        }
    }
}

struct MDProductsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var searchString: String = ""
    
    @State private var showAddProduct: Bool = false
    @State private var productToDelete: MDProduct? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var toastType: MDToastType?
    
    private let dataToUpdate: [ObjectEntities] = [.products, .locations, .product_groups]
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func deleteItem(itemToDelete: MDProduct) {
        productToDelete = itemToDelete
        showDeleteAlert.toggle()
    }
    private func deleteProduct(toDelID: Int) {
        grocyVM.deleteMDObject(object: .products, id: toDelID, completion: { result in
            switch result {
            case let .success(message):
                grocyVM.postLog(message: "Deleting product was successful. \(message)", type: .info)
                updateData()
            case let .failure(error):
                grocyVM.postLog(message: "Deleting product failed. \(error)", type: .error)
                toastType = .failDelete
            }
        })
    }
    
    private var filteredProducts: MDProducts {
        grocyVM.mdProducts
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter( {dataToUpdate.contains($0) }).count == 0 {
#if os(macOS)
            NavigationView{
                bodyContent
                    .frame(minWidth: Constants.macOSNavWidth)
            }
#else
            bodyContent
#endif
        } else {
            ServerProblemView()
                .navigationTitle(LocalizedStringKey("str.md.products"))
        }
    }
    
    var bodyContent: some View {
        content
            .toolbar (content: {
                ToolbarItemGroup(placement: .primaryAction, content: {
#if os(macOS)
                    RefreshButton(updateData: { updateData() })
#endif
                    Button(action: {
                        showAddProduct.toggle()
                    }, label: {
                        Image(systemName: MySymbols.new)
                    })
                })
            })
            .navigationTitle(LocalizedStringKey("str.md.products"))
#if os(iOS)
            .sheet(isPresented: $showAddProduct, content: {
                NavigationView {
                    MDProductFormView(isNewProduct: true, showAddProduct: $showAddProduct, toastType: $toastType)
                }
            })
#endif
    }
    
    var content: some View {
        List{
            if grocyVM.mdProducts.isEmpty {
                Text(LocalizedStringKey("str.md.products.empty"))
            } else if filteredProducts.isEmpty {
                Text(LocalizedStringKey("str.noSearchResult"))
            }
#if os(macOS)
            if showAddProduct {
                NavigationLink(destination: MDProductFormView(isNewProduct: true, showAddProduct: $showAddProduct, toastType: $toastType), isActive: $showAddProduct, label: {
                    NewMDRowLabel(title: "str.md.product.new")
                })
            }
#endif
            ForEach(filteredProducts, id:\.id) { product in
                NavigationLink(destination: MDProductFormView(isNewProduct: false, product: product, showAddProduct: Binding.constant(false), toastType: $toastType)) {
                    MDProductRowView(product: product)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: product) },
                           label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .onAppear(perform: {
            grocyVM.requestData(objects: dataToUpdate, ignoreCached: false)
        })
        .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
        .refreshable { updateData() }
        .animation(.default, value: filteredProducts.count)
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successAdd || toastType == .successEdit), content: { item in
            switch item {
            case .successAdd:
                Label(LocalizedStringKey("str.md.new.success"), systemImage: MySymbols.success)
            case .failAdd:
                Label(LocalizedStringKey("str.md.new.fail"), systemImage: MySymbols.failure)
            case .successEdit:
                Label(LocalizedStringKey("str.md.edit.success"), systemImage: MySymbols.success)
            case .failEdit:
                Label(LocalizedStringKey("str.md.edit.fail"), systemImage: MySymbols.failure)
            case .failDelete:
                Label(LocalizedStringKey("str.md.delete.fail"), systemImage: MySymbols.failure)
            }
        })
        .alert(LocalizedStringKey("str.md.product.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let toDelID = productToDelete?.id {
                    deleteProduct(toDelID: toDelID)
                }
            }
        }, message: { Text(productToDelete?.name ?? "Name not found") })
    }
}

struct MDProductsView_Previews: PreviewProvider {
    static var previews: some View {
#if os(macOS)
        MDProductsView()
#else
        NavigationView() {
            MDProductsView()
        }
#endif
    }
}
