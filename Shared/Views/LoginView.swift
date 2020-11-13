//
//  LoginView.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 8/15/19.
//  Copyright © 2019 Grey Patterson. All rights reserved.
//

import SwiftUI

struct LoginView: View {
    @State var username: String = ""
    @State var password: String = ""
    @AppStorage("rememberMe") var rememberMe = false
    
    @AppStorage("rememberedEmail") var rememberedEmail = ""
    @AppStorage("rememberedPassword") var rememberedPassword = ""
    
    var body: some View {
        VStack {
            Text("Log In").font(.largeTitle)
            Spacer()
            
            Form {
                
                TextField("Username", text: $username).textContentType(.username)
                SecureField("Password", text: $password).textContentType(.password)
                Toggle("Remember me", isOn: $rememberMe)
                Button(action: {
                    AuthService.shared.login(username: self.username, password: self.password)
                    if (rememberMe){
                        rememberedEmail = username
                        rememberedPassword = password
                    } else {
                        rememberedEmail = ""
                        rememberedPassword = ""
                    }
                }) {
                    Text("Login")
                }.disabled(!canLogin)
            }.navigationTitle(Text("Log In"))
            .onAppear{
                if (rememberMe){
                    username = rememberedEmail
                    password = rememberedPassword
                }
            }
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
