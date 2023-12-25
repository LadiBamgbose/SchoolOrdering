// Account.swift
import SwiftUI

struct CreditCard: Identifiable, Decodable {
    var id = UUID()
    var cardNumber: String
    var cardExpiration: String
    var cardCVC: String
}

struct Account: View {
    @State private var userCreditCards: [CreditCard] = [] // Use this array for user cards
    @Binding var userEmail: String
    @EnvironmentObject private var userEmailManager: UserEmailManager
    @State private var isLoggedIn: Bool = true // For testing, set this to true

    @State private var isAddCardSheetPresented = false
    @State private var newCardNumber: String = ""
    @State private var newCardExpiration: String = ""
    @State private var newCardCVC: String = ""

    @State private var isLoggedOut: Bool = false

    struct UserCardsResponse: Decodable {
        let success: Bool
        let userCards: [CreditCard]
    }

    private func fetchUserCards() {
        print("Fetching user cards...")
        guard let userEmail = userEmailManager.userEmail else {
            print("User email is missing")
            return
        }

        guard let url = URL(string: "http://localhost:3000/getUserCards?email=\(userEmail)") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching user cards:", error.localizedDescription)
                // Handle error if needed
            } else if let data = data {
                do {
                    let decoder = JSONDecoder()

                    print("Raw Data:", String(data: data, encoding: .utf8) ?? "Failed to convert data to string")

                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let dictionary = json as? [String: Any],
                       let success = dictionary["success"] as? Bool,
                       success,
                       let userCardsArray = dictionary["userCards"] as? [[String: Any]] {

                        let cards = userCardsArray.map { cardDict in
                            CreditCard(
                                cardNumber: cardDict["cardNumber"] as? String ?? "",
                                cardExpiration: cardDict["expirationDate"] as? String ?? "",
                                cardCVC: "\(cardDict["cvv"] ?? "")" // Ensure cvv is handled properly
                            )
                        }

                        print("Fetched user cards:", cards)
                        DispatchQueue.main.async {
                            userCreditCards = cards
                        }
                    } else {
                        print("Failed to parse JSON as expected")
                    }
                } catch {
                    print("Error decoding user cards:", error.localizedDescription)
                    // Handle decoding error if needed
                }
            }
        }
        .resume()
    }



    private func sendCardToServer() {
        guard let userEmail = userEmailManager.userEmail else {
            print("User email is missing")
            return
        }

        guard let url = URL(string: "http://localhost:3000/addCard") else {
            print("Invalid URL")
            return
        }

        let cardData = ["email": userEmail, "cardNumber": newCardNumber, "expirationDate": newCardExpiration, "cvv": newCardCVC]
        let jsonData = try? JSONSerialization.data(withJSONObject: cardData)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending card data:", error.localizedDescription)
                // Handle error if needed
            } else if let data = data {
                // Assuming your server sends a JSON response
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let success = json["success"] as? Bool {
                    if success {
                        // Card added successfully
                        print("Card added successfully")
                    } else {
                        // Handle card addition failure
                        print("Failed to add card")
                    }
                }
            }
        }
        .resume()
    }

    private func sendCardDeletionToServer(cardNumber: String) {
        guard let userEmail = userEmailManager.userEmail else {
            print("User email is missing")
            return
        }

        guard let url = URL(string: "http://localhost:3000/deleteCard") else {
            print("Invalid URL")
            return
        }

        let cardData = ["email": userEmail, "cardNumber": cardNumber]
        let jsonData = try? JSONSerialization.data(withJSONObject: cardData)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending card deletion request:", error.localizedDescription)
                // Handle error if needed
            } else if let data = data {
                // Assuming your server sends a JSON response
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let success = json["success"] as? Bool {
                    if success {
                        // Card deleted successfully
                        print("Card deleted successfully")
                    } else {
                        // Handle card deletion failure
                        print("Failed to delete card")
                    }
                }
            }
        }
        .resume()
    }

    var body: some View {
        VStack {
            if let loggedInEmail = userEmailManager.userEmail {
                // User is logged in
                Text("Welcome \(userEmail)")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)

                Text("Here are your available cards")
                    .font(.headline)
                    .padding(.bottom, 10)

                List {
                    ForEach(userCreditCards) { card in
                        CardRow(card: card)
                            .padding()
                    }
                    .onDelete(perform: deleteCard)
                }
                .listStyle(PlainListStyle())

                Button("Add a Card") {
                    isAddCardSheetPresented.toggle()
                }
                .sheet(isPresented: $isAddCardSheetPresented) {
                    VStack {
                        Text("Add a Card")
                            .font(.title)
                            .padding()

                        TextField("Card Number", text: $newCardNumber)
                            .padding()
                            .keyboardType(.numberPad)

                        TextField("Expiration (MM/YY)", text: $newCardExpiration)
                            .padding()
                            .keyboardType(.numberPad)

                        TextField("CVC", text: $newCardCVC)
                            .padding()
                            .keyboardType(.numberPad)

                        Button("Add Card") {
                            userCreditCards.append(CreditCard(
                                cardNumber: newCardNumber,
                                cardExpiration: newCardExpiration,
                                cardCVC: newCardCVC
                            ))
                            print("Button tapped!")
                            sendCardToServer()
                            isAddCardSheetPresented.toggle()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }

                Button("Sign Out") {
                    signOutUser()
                }
                .fullScreenCover(isPresented: $isLoggedOut, content: {
                    LoginView().environmentObject(userEmailManager)
                })
                .onAppear {
                        fetchUserCards()
                }
                
            } else {
                // User is not logged in, handle accordingly
                Text("Please log in to view account")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                    
                // Optionally, provide UI or button for login
            }
        }
    }

    private func deleteCard(at offsets: IndexSet) {
        guard let userEmail = userEmailManager.userEmail else {
            print("User email is missing")
            return
        }

        // Iterate over the indices provided by 'offsets'
        for index in offsets {
            // Ensure the index is within the bounds of the 'userCreditCards' array
            guard index < userCreditCards.count else {
                print("Invalid index")
                return
            }

            // Get the card number at the specified index
            let cardNumber = userCreditCards[index].cardNumber

            // Call the function to send card deletion request to the server
            sendCardDeletionToServer(cardNumber: cardNumber)
        }

        // Remove the selected cards from 'userCreditCards'
        userCreditCards.remove(atOffsets: offsets)
    }

    private func signOutUser() {
        guard let url = URL(string: "http://localhost:3000/signout") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error signing out:", error)
                // Handle error if needed
            } else if let data = data {
                // Assuming your server sends a JSON response
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let success = json["success"] as? Bool {
                    if success {
                        // Sign-out successful, update UI accordingly
                        isLoggedOut.toggle()
                    } else {
                        // Handle sign-out failure
                        print("Sign-out failed")
                    }
                }
            }
        }
        .resume()
    }
}

struct CardRow: View {
    let card: CreditCard

    var body: some View {
        HStack {
            Text("Card Number: \(card.cardNumber)\nExpiration: \(card.cardExpiration)\nCVC: \(card.cardCVC)")
            Spacer()
        }
    }
}

#if DEBUG
struct Account_Previews: PreviewProvider {
    static var previews: some View {
        Account(userEmail: .constant("sample@sju.edu")).environmentObject(UserEmailManager.shared)
    }
}
#endif
