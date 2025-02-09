//
//  ContentView.swift
//  Swap and Share 2
//
//  Created by Carl Hockings on 22/11/24.
//



import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var newSwapCount: Int = 0 // Tracks the number of new swaps
    @AppStorage("currentUserID") private var currentUserID: String? // Store the current user's ID
    @State private var swapRequest: [SwapRequest] = [] // State to store items from Supabase

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Top bar with Login and Settings Icons
                        HomeCard {
                            HStack {
                                NavigationLink(destination: LoginView()) {
                                    Image(systemName: "person.circle")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                }
                                Spacer()
                                Text("Swaps")
                                    .font(.title2)
                                    .bold()
                                Spacer()
                                NavigationLink(destination: SettingsView()) {
                                    Image(systemName: "gearshape.fill")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                }
                            }
                        }
                        
                        HomeCard {
                            VStack(spacing: 16) {
                                // Button Pair: Search and Browse Categories
                                HStack(spacing: 12) {
                                    // Search Button
                                    NavigationLink(destination: SearchView()) {
                                        HStack {
                                            Image(systemName: "magnifyingglass")
                                                .font(.title3)
                                                .foregroundColor(.white)
                                            Text("Search")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    }

                                    // Browse Categories Button
                                    NavigationLink(destination: CategorySelectionView(categories: [
                                        "Books",
                                        "Clothes",
                                        "Furniture",
                                        "Home Appliances",
                                        "Electronics",
                                        "Sports",
                                        "Miscellaneous",
                                        "Home Goods",
                                        "Vehicles & Parts",
                                        "Bicycles",
                                        "Beauty",
                                        "Tools"
                                    ]) { selectedCategory in
                                        print("User selected category: \(selectedCategory)") // Handle category selection logic
                                    }) {
                                        HStack {
                                            Image(systemName: "square.grid.2x2")
                                                .font(.title3)
                                                .foregroundColor(.white)
                                            Text("Browse")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.green)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    }
                                }
                                .padding(.horizontal)

                                // Category Slider Cards
                                ScrollView {
                                    VStack(spacing: 20) {
                                        ForEach(["Books", "Clothes", "Home Goods", "Electronics", "Vehicles & Parts"], id: \.self) { category in
                                            CategorySliderCard(categoryName: category)
                                        }
                                    }
                                }
                            }
                        }

                        .padding(.top)
                    }

                    .padding(.horizontal)
                }

                // Bottom Taskbar with three navigation buttons
                HStack {
                    Spacer()
                    NavigationLink(destination: AddItemView()) {
                        TaskbarButton(iconName: "plus", label: "Add Item", backgroundColor: Color.blue, badgeCount: nil)
                    }
                    Spacer()
                    NavigationLink(destination: MyItemsView()) {
                        TaskbarButton(iconName: "list.bullet", label: "My Items", backgroundColor: Color.green, badgeCount: nil)
                    }
                    Spacer()
                    NavigationLink(destination: SwapRequestManager()) {
                        TaskbarButton(
                            iconName: "arrow.2.circlepath",
                            label: "Swaps",
                            backgroundColor: Color.orange,
                            badgeCount: newSwapCount // Display badge count
                        )
                    }
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchNewSwaps() // Fetch swap data whenever the view appears
            }
        }
    }

    // MARK: - Fetch New Swaps
    private func fetchNewSwaps() {
        Task {
            do {
                // Log: Starting fetch process
                print("Starting fetchNewSwaps...")
                
                // Ensure the current user's ID is available
                guard let currentUserID = await SupabaseManager.shared.getCurrentUserID() else {
                    print("Error: User ID not available.")
                    return
                }
                print("Current User ID: \(currentUserID)")
                
                // Query the swap_requests table for unread notifications involving the user
                let query = SupabaseManager.shared.client.database
                    .from("swap_requests")
                    .select(columns: "id, Notification, receiver_id, requester_id")
                    .eq(column: "Notification", value: true)
                    .or(filters: "receiver_id.eq.\(currentUserID),requester_id.eq.\(currentUserID)")

                
                print("Executing query for unread swap notifications...")
                
                // Fetch and decode the response into an array of SwapRequest objects
                let response: [SwapRequest] = try await query.execute().value
                
                // Assign the fetched response to the `swapRequest` state
                self.swapRequest = response
                print ("responce fetched")
                
                // Filter for swaps with `Notification` set to true
                let swapsWithNotification = response.filter { $0.Notification }
                
                // Update the new swap count based on the filtered results
                await MainActor.run {
                    newSwapCount = swapsWithNotification.count
                }
                
                print("Query successful. Number of swaps fetched: \(swapsWithNotification.count)")
            } catch {
                print("Error fetching or updating swap notifications: \(error.localizedDescription)")
            }
        }
    }

    struct SwapRequest: Codable, Identifiable {
        let id: Int
        let Notification: Bool
        let requester_id: String
        let receiver_id: String
    }
}

// HomeCard consistent with AddItemView
struct HomeCard<Content: View>: View {
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// TaskbarButton for buttons in the taskbar
struct TaskbarButton: View {
    let iconName: String
    let label: String
    let backgroundColor: Color
    let badgeCount: Int? // Optional badge count for notifications

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(backgroundColor)
                    .clipShape(Circle())
                Text(label)
                    .font(.footnote)
                    .foregroundColor(.primary)
            }

            // Badge view
            if let badgeCount = badgeCount, badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 16, y: -10)
            }
        }
    }
}

// CategoryBox
struct CategoryBox: View {
    var imageName: String
    var label: String
    var backgroundColor: Color

    var body: some View {
        VStack {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 70)
                .padding(8)
            Text(label)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .frame(height: 130)
        .background(backgroundColor)
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
