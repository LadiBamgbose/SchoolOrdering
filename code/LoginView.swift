import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var loginError: Bool = false
    @State private var isMainTabViewPresented: Bool = false
    @State private var isRegistrationViewPresented: Bool = false
    @StateObject private var userEmailManager = UserEmailManager.shared

    var body: some View {
        VStack {
            Text("Sign In")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("SJU Email address", text: $email)
                .padding()
                .font(.title3)
                .background(Color.gray)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            SecureField("Password", text: $password)
                .padding()
                .font(.title3)
                .background(Color.gray)

            Button("Sign In") {
                // Check email and password using isValidLogin
                isValidLogin { success in
                    if success {
                        withAnimation {
                            print("Valid login. Logging in...")
                            userEmailManager.userEmail = email
                            isMainTabViewPresented = true
                            loginError = false
                        }
                    } else {
                        withAnimation {
                            print("Invalid login. Check email and password.")
                            loginError = true
                        }
                    }
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(loginError ? Color.red : Color.clear, lineWidth: 2)
            )
            .padding(.top, 20)

            // Add registration button
            Button("Register") {
                isRegistrationViewPresented.toggle()
            }
            .padding()
            .foregroundColor(.blue)
        }
        .padding()
        .fullScreenCover(isPresented: $isMainTabViewPresented, content: {
            MainTabView(userEmail: email)
        })
        .fullScreenCover(isPresented: $isRegistrationViewPresented, content: {
            RegistrationView(isPresented: $isRegistrationViewPresented)
        })
        .environmentObject(userEmailManager)
    }

    private func isValidLogin(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:3000/signin") else {
            print("Invalid URL")
            completion(false)
            return
        }

        let userData = ["email": email, "password": password]
        let jsonData = try? JSONSerialization.data(withJSONObject: userData)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                completion(false)
                return
            }

            if let data = data {
                let responseString = String(data: data, encoding: .utf8)
                print("Response: \(responseString ?? "")")

                // Handle the response here and return true or false based on authentication result
                // You might need to parse the response JSON and check if the authentication was successful

                // Example: Assuming your response is a JSON with a "success" key
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let success = json["success"] as? Bool {
                    completion(success)
                    return
                }
            }
            

            completion(false)
        }
        .resume()
    }
}

struct RegistrationView: View {
    @Binding var isPresented: Bool
    @State private var newUsername: String = ""
    @State private var newPassword: String = ""

    var body: some View {
        VStack {
            Text("Register")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Username", text: $newUsername)
                .padding()
                .font(.title3)
                .background(Color.gray)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            SecureField("Password", text: $newPassword)
                .padding()
                .font(.title3)
                .background(Color.gray)

            Button("Register") {
                registerUser(email: newUsername, password: newPassword) { result in
                    switch result {
                    case .success(let data):
                        print("Registration success: \(data)")
                        isPresented = false
                    case .failure(let error):
                        print("Registration error: \(error.localizedDescription)")
                    }
                }
            }

            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }

    private func registerUser(email: String, password: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: "http://localhost:3000/newUser") else {
            print("Invalid URL")
            return
        }

        let userData = ["email": email, "password": password]
        let jsonData = try? JSONSerialization.data(withJSONObject: userData)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = data {
                completion(.success(data))
            }
        }
        .resume()
    }
}


#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
#endif
