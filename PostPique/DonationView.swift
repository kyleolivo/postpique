import SwiftUI
import StoreKit

struct DonationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var products: [Product] = []
    @State private var purchaseError: String?
    @State private var isPurchasing = false
    
    let productIDs = [
        "com.kyleolivo.PostPique.tip.small",
        "com.kyleolivo.PostPique.tip.medium",
        "com.kyleolivo.PostPique.tip.large"
    ]
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("Support the App")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .overlay(alignment: .trailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .padding(.trailing)
                }
                .padding(.vertical, 16)
                
                // Content
                VStack(spacing: 40) {
                    VStack(spacing: 16) {
                        Text("☕")
                            .font(.system(size: 60))
                        
                        Text("Buy me a coffee!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Your support helps keep this app running and\ncaffeine flowing.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("TIP OPTIONS")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                        
                        if products.isEmpty {
                            // Loading or fallback UI
                            VStack(spacing: 0) {
                                TipButtonPlaceholder(emoji: "📝", name: "Small Tip", price: "$1.99")
                                Divider().background(Color.gray.opacity(0.3))
                                TipButtonPlaceholder(emoji: "📚", name: "Medium Tip", price: "$4.99")
                                Divider().background(Color.gray.opacity(0.3))
                                TipButtonPlaceholder(emoji: "🚀", name: "Large Tip", price: "$9.99")
                            }
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(products) { product in
                                    TipButton(
                                        product: product,
                                        isPurchasing: isPurchasing,
                                        onPurchase: { purchase(product) }
                                    )
                                    
                                    if product.id != products.last?.id {
                                        Divider()
                                            .background(Color.gray.opacity(0.3))
                                    }
                                }
                            }
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                    
                    if let error = purchaseError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    Spacer()
                }
            }
        }
        .task {
            await loadProducts()
        }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
                .sorted { p1, p2 in
                    productIDs.firstIndex(of: p1.id) ?? 0 < productIDs.firstIndex(of: p2.id) ?? 0
                }
        } catch {
            purchaseError = "Unable to load products"
        }
    }
    
    func purchase(_ product: Product) {
        Task {
            isPurchasing = true
            purchaseError = nil
            
            do {
                let result = try await product.purchase()
                
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        await transaction.finish()
                        dismiss()
                    case .unverified:
                        purchaseError = "Purchase could not be verified"
                    }
                case .userCancelled:
                    break
                case .pending:
                    purchaseError = "Purchase is pending"
                @unknown default:
                    purchaseError = "Unknown error occurred"
                }
            } catch {
                purchaseError = error.localizedDescription
            }
            
            isPurchasing = false
        }
    }
}

struct TipButton: View {
    let product: Product
    let isPurchasing: Bool
    let onPurchase: () -> Void
    
    var emoji: String {
        switch product.id {
        case "com.kyleolivo.PostPique.tip.small":
            return "📝"
        case "com.kyleolivo.PostPique.tip.medium":
            return "📚"
        case "com.kyleolivo.PostPique.tip.large":
            return "🚀"
        default:
            return "📝"
        }
    }
    
    var tipName: String {
        switch product.id {
        case "com.kyleolivo.PostPique.tip.small":
            return "Small Tip"
        case "com.kyleolivo.PostPique.tip.medium":
            return "Medium Tip"
        case "com.kyleolivo.PostPique.tip.large":
            return "Large Tip"
        default:
            return product.displayName
        }
    }
    
    var body: some View {
        Button(action: onPurchase) {
            HStack {
                Text(emoji)
                    .font(.title2)
                
                Text(tipName)
                    .foregroundColor(.white)
                    .font(.body)
                
                Spacer()
                
                if isPurchasing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(product.displayPrice)
                        .foregroundColor(.gray)
                        .font(.body)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }
}

struct TipButtonPlaceholder: View {
    let emoji: String
    let name: String
    let price: String
    
    var body: some View {
        HStack {
            Text(emoji)
                .font(.title2)
            
            Text(name)
                .foregroundColor(.white)
                .font(.body)
            
            Spacer()
            
            Text(price)
                .foregroundColor(.gray)
                .font(.body)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    DonationView()
}