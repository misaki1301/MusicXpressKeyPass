//
//  RegisterView.swift
//  MusicXpressKeyPass
//
//  Created by Paul Frank on 15/06/24.
//

import SwiftUI

struct RegisterView: View {
	
	@State var username: String = ""
	@State var password: String = ""
	@State var confirmPassword: String = ""
	@State var showSheetPasskey: Bool = false
	
	var body: some View {
		VStack {
			VStack(alignment: .leading) {
				Text("Username")
				TextField("Ej. pedro202", text: $username)
				Text("Password")
				TextField("", text: $password)
				Text("Confirm password")
				TextField("", text: $confirmPassword)
			}
			.padding(.horizontal, 32)
			VStack {
				Button {
					
				} label: {
					Text("Sign up")
				}
				.buttonStyle(BorderedProminentButtonStyle())
//				Button {
//					
//				} label: {
//					Image(systemName: "person.badge.key.fill")
//					Text("PassKey option")
//				}
				NavigationLink("PassKey", destination: {
					PassKeyRegisterView()
				})
				.buttonStyle(BorderedProminentButtonStyle())
			}
			.padding()

		}
		.textFieldStyle(.roundedBorder)
		.navigationTitle("Create account")
	}
}

#Preview {
    RegisterView()
}
