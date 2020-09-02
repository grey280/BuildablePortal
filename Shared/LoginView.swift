//
//  LoginView.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import SwiftUI

struct LoginView: View {
    @State var username: String = "gpatterson@buildableworks.com"
    @State var password: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Username", text: $username).textContentType(.username)
                SecureField("Password", text: $password).textContentType(.password)
                Button(action: {
                    AuthService.shared.login(username: self.username, password: self.password)
                }) {
                    Text("Login")
                }.disabled(!canLogin)
            }.navigationBarTitle(Text("Log In"))
        }
    }
    
    var canLogin: Bool{
        return !username.isEmpty && !password.isEmpty
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
#endif
