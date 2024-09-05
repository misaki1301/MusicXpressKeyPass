//
//  PassKeyRegisterView.swift
//  MusicXpressKeyPass
//
//  Created by Paul Frank on 17/06/24.
//

import SwiftUI

struct PassKeyRegisterView: View {
	
	@EnvironmentObject var auth: AuthorizationManager
	@Environment(\.authorizationController) private var authorizationController
	@State var username: String = ""
	
    var body: some View {
		VStack(spacing: 16) {
			TextField("Nombre de usuario", text: $username)
			Button {
				Task {
					await auth.registerUserCredential(authorizationController: authorizationController, username: username)
				}
			} label: {
				Image(systemName: "person.badge.key.fill")
				Text("Register with passkey")
				
			}
			.buttonStyle(BorderedProminentButtonStyle())

		}
		.padding()
		.textFieldStyle(.roundedBorder)
		.navigationTitle("Registro con Passkey")
    }
}

#Preview {
    PassKeyRegisterView()
}
