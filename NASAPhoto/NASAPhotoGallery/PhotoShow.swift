import SwiftUI
import Combine

struct NASAPhotoDataModel: Codable, Identifiable {
    var id: String { date ?? url ?? UUID().uuidString }
    let copyright: String?
    let date: String?
    let explanation: String?
    let url: String?
    let title: String?
    let media_type: String?
    
    private enum CodingKeys: String, CodingKey {
        case copyright, date, explanation, url, title, media_type
    }
}

class FavoritesManager: ObservableObject {
    @AppStorage("favoriteAPODs") private var storedFavoritesData: Data = Data()
    
    private var storedFavorites: [String] {
        get {
            guard !storedFavoritesData.isEmpty else { return [] }
            return (try? JSONDecoder().decode([String].self, from: storedFavoritesData)) ?? []
        }
        set {
            storedFavoritesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    func isFavorite(id: String) -> Bool {
        storedFavorites.contains(id)
    }
    
    func toggleFavorite(id: String) {
        var current = storedFavorites
        if let index = current.firstIndex(of: id) {
            current.remove(at: index)
        } else {
            current.append(id)
        }
        storedFavorites = current
    }
    
    var favorites: [String] {
        storedFavorites
    }
}

// MARK: ViewModel
class NasaPhotoShowViewModel: ObservableObject {
    @Published var data: [NASAPhotoDataModel] = []
    var cancellable = Set<AnyCancellable>()
    
    func fetchData(date: Date) {
//        let apikey = "TjpgPqLnJPfDXaFNJKQfZ9GavOteN3QeA0KGfQD6"
        let apikey = "DEMO_KEY"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let urlString = "https://api.nasa.gov/planetary/apod?api_key=\(apikey)&date=\(formatter.string(from: date))"
        
        guard let url = URL(string: urlString) else {return}
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: NASAPhotoDataModel.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case let .failure(error) = completion {
                    print("APOD fetch error", error)
                }
            } receiveValue: { item in
                self.data = [item]
            }
            .store(in: &cancellable)
    }
}

// MARK: - View
struct PhotoShow: View {
    @StateObject var viewModel = NasaPhotoShowViewModel()
    @StateObject private var favoritesManager = FavoritesManager()
    @State private var selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    
    private let minAPODDate = Calendar.current.date(
        from: DateComponents(year: 1995, month: 6, day: 16)
    )!
    
    private let maxAPODDate = Calendar.current.date(
        byAdding: .day,
        value: -1,
        to: Date()
    )!
    
    @State private var isDarkMode = false
    @State var showFullPhoto: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Dark Mode", isOn: $isDarkMode)
                                
                // Date Picker
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: minAPODDate...maxAPODDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .onChange(of: selectedDate) { _, newValue in
                    viewModel.fetchData(date: newValue)
                }
                
                Divider()
                
                if let item = viewModel.data.first {
                    
                    // Image
                    if let urlString = item.url,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .onTapGesture {
                                    showFullPhoto = true
                                }
                        } placeholder: {
                            ProgressView()
                                .frame(height: 250)
                        }
                        .sheet(isPresented: $showFullPhoto) {
                            FullDetailView(imageURL: urlString)
                                .presentationDetents([.medium, .large])
                        }
                    }
                    HStack {
                        Text(item.title ?? "No Title")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button {
                            favoritesManager.toggleFavorite(id: item.id)
                        } label: {
                            Image(systemName:
                                    favoritesManager.isFavorite(id: item.id) ? "heart.fill" : "heart"
                            )
                            .font(.title2)
                            .foregroundColor(.red)
                        }
                    }
                    
                    // Date
                    Text("Date: \(item.date ?? "N/A")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Media Type
                    Text("Media Type: \(item.media_type ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Explanation
                    Text(item.explanation ?? "No explanation available")
                        .font(.body)
                    
                    // Copyright
                    Text("© \(item.copyright ?? "NASA / Public Domain")")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    ProgressView("Loading...")
                }
            }
            .padding()
        }
        .navigationTitle("NASA APOD")
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            viewModel.fetchData(date: selectedDate)
        }
    }
}


// MARK: - Preview
#Preview {
    NavigationStack {
        PhotoShow()
    }
}

