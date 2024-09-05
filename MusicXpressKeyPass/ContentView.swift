//
//  ContentView.swift
//  MusicXpressKeyPass
//
//  Created by Paul Frank on 14/06/24.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
	@StateObject var auth: AuthorizationManager = AuthorizationManager()
    @Query private var items: [Item]
	
	var body: some View {
		RouterView {
			LoginView()
		}.environmentObject(auth)
	}
}

struct LoginView: View {
	@EnvironmentObject var router: Router
	@EnvironmentObject var auth: AuthorizationManager
	@Environment(\.authorizationController) private var authorizationController
	@State private var username: String = ""
	@State private var password: String = ""
	
	var body: some View {
		VStack {
			Spacer()
			Image(systemName: "leaf.fill")
				.resizable()
				.frame(width: 64, height: 64)
				.foregroundColor(.green)
			VStack {
				TextField("username", text: $username)
				SecureField("password", text: $password)
				Button(action: {}) {
					Text("Log in")
				}.padding(.top, 16)
			}
			.padding()
			Spacer()
			Button(action: {Task {await auth.signIntoPassKeyAccount(authorizationController: authorizationController, username: "misaki1301")}
			}) {
				Image(systemName: "person.badge.key.fill")
				Text("Sign in with Passkey")
			}.buttonStyle(.bordered)
			Spacer()
			Button(action: {
				navigateToRegister()
			}) {
				Text("Create account")
			}
		}.textFieldStyle(RoundedBorderTextFieldStyle())
			.onAppear {
				router
					.setCurrentSheet(for:
										RegisterView()
						.environmentObject(auth)
				)
			}
			.onDisappear {
				router.setCurrentSheet(for: EmptyView())
			}
	}
	
	private func navigateToRegister() {
		router.isSheetPresented.toggle()
	}
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
