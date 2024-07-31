import Foundation

// MARK: - Environment

func environmentVariable(_ variable: String) -> String? {
    return ProcessInfo.processInfo.environment[variable]
}

// MARK: - Constants

let token = environmentVariable("ARTIFACTS_TOKEN")!

let baseURL = "https://api.artifactsmmo.com/"

// MARK: - Models

struct Point: Codable {
    var x: Int
    var y: Int
}

struct Character {
    let name: String
    
    static let anti = Character(name: "anti")
    
    var urlRepresentation: String {
        return "my/\(name)"
    }
}

struct Announcement: Codable {
    let message: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case message
        case createdAt = "created_at"
    }
}

struct StatusInfo: Decodable {
    let status: String
    let version: String
    let charactersOnline: Int
    let announcements: [Announcement]
    let lastWipe: String
    let nextWipe: String
    
    init(from decoder: any Decoder) throws {
        let parentContainer = try decoder.container(keyedBy: CodingKeys.self)
        let container = try parentContainer.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .data)
        self.status = try container.decode(String.self, forKey: .status)
        self.version = try container.decode(String.self, forKey: .version)
        self.charactersOnline = try container.decode(Int.self, forKey: .charactersOnline)
        self.announcements = try container.decode([Announcement].self, forKey: .announcements)
        self.lastWipe = try container.decode(String.self, forKey: .lastWipe)
        self.nextWipe = try container.decode(String.self, forKey: .nextWipe)
    }
    
    enum NestedCodingKeys: String, CodingKey {
        case status
        case version
        case charactersOnline = "characters_online"
        case announcements
        case lastWipe = "last_wipe"
        case nextWipe = "next_wipe"
    }
    
    enum CodingKeys: String, CodingKey {
        case data
    }
}

// MARK: - Network Service

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

func makeRequest(with endpoint: Endpoint) -> URLRequest {
    var request = URLRequest(url: endpoint.url)
    request.httpMethod = endpoint.httpMethod
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return request
}

// MARK: - Endpoint

enum Endpoint {
    case status
    case action(Character, Action)
    
    var httpMethod: String {
        switch self {
        case .status: return HTTPMethod.get.rawValue
        case .action: return HTTPMethod.post.rawValue
        }
    }
    
    var url: URL {
        let url: String
        switch self {
        case .status:
            url = baseURL
        case let .action(character, action):
            url = baseURL + character.urlRepresentation + action.urlRepresentation
        }
        return URL(string: url)!
    }
}

// MARK: - Methods

func getStatus() {
    let request = makeRequest(with: .status)
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error {
            print("Error with \(error)")
        } else if let data {
            print("Response \(response as? HTTPURLResponse)")
            
            do {
                let decoder = JSONDecoder()
                let decodedStatus = try decoder.decode(StatusInfo.self, from: data)
                print("Status \(decodedStatus)")
            } catch {
                print("Error decoding \(error)")
            }
        }
        semaphore.signal()
    }
    task.resume()
    semaphore.wait()
}

// MARK: - Game Mechanics

enum Action: String {
    case move
    case attack
    
    var urlRepresentation: String {
        return "action/\(rawValue)"
    }
}

// MARK: - Game

let semaphore = DispatchSemaphore(value: 0)
print("Starting task")
getStatus()
print("Ending task")
