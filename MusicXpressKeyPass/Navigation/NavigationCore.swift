//
//  NavigationCore.swift
//  MusicXpressKeyPass
//
//  Created by Paul Frank on 14/06/24.
//

import Foundation
import SwiftUI

final class Router: ObservableObject {
	
	enum Route: Hashable {
		case login
		//case register
		case home
	}
	
	@Published var path: NavigationPath = NavigationPath()
	
	@Published var isSheetPresented: Bool = false
	
	private var contentSheet: any View = EmptyView()
	
	@ViewBuilder func view(for route: Route) -> some View {
		switch route {
			case .login:
				LoginView()
			//case .register:
				//RegisterView()
			case .home:
				HomeView()
		}
	}
	
	func navigateTo(_ appRoute: Route) {
		path.append(appRoute)
	}
	
	func navigateBack() {
		path.removeLast()
	}
	
	func popToRoot() {
		path.removeLast(path.count)
	}
	
	@ViewBuilder
	func getCurrentSheet() -> any View {
		contentSheet
	}
	
	func setCurrentSheet(for sheet: any View) {
		self.contentSheet = AnyView(sheet)
	}
}

struct RouterView<Content: View>: View {
	
	@StateObject var router: Router = Router()
	
	private let content: Content
	
	init(@ViewBuilder content: @escaping () -> Content) {
		self.content = content()
	}
	
	var body: some View {
		NavigationStack(path: $router.path) {
			content
				.navigationDestination(for: Router.Route.self) { route in
					router.view(for: route)
				}
				.sheet(isPresented: $router.isSheetPresented, onDismiss: nil) {
					NavigationStack {
						AnyView(router.getCurrentSheet())
					}
				}

		}.environmentObject(router)
	}
	
}
