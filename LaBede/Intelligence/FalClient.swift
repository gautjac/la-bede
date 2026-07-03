import Foundation

/// A minimal client for Fal.ai's synchronous image endpoints. La Bédé uses it to
/// draw each comic panel with a real text-to-image diffusion model (Flux), which
/// — unlike Apple's now-removed `ImageCreator` — actually follows the sentence
/// and produces strong, styled art.
///
/// We hit the synchronous `https://fal.run/<model>` endpoint: POST a prompt,
/// receive a JSON payload with a hosted image URL, download it, return the bytes.
struct FalClient {

    /// The Flux variant to call. `dev` favours quality; `schnell` favours speed.
    enum Model: String, CaseIterable, Sendable {
        case fluxDev = "fal-ai/flux/dev"
        case fluxSchnell = "fal-ai/flux/schnell"

        /// French label for the settings toggle.
        var label: String {
            switch self {
            case .fluxDev: return "Qualité (Flux dev)"
            case .fluxSchnell: return "Rapide (Flux schnell)"
            }
        }
    }

    enum FalError: LocalizedError {
        case noKey
        case http(status: Int, body: String)
        case badResponse
        case noImage
        case imageDownloadFailed

        var errorDescription: String? {
            switch self {
            case .noKey: return "Aucune clé Fal.ai."
            case let .http(status, body):
                let trimmed = body.prefix(160)
                return "Fal.ai a renvoyé \(status)\(trimmed.isEmpty ? "" : " : \(trimmed)")"
            case .badResponse: return "Réponse Fal.ai illisible."
            case .noImage: return "Fal.ai n'a renvoyé aucune image."
            case .imageDownloadFailed: return "Échec du téléchargement de l'image."
            }
        }
    }

    let apiKey: String
    let model: Model
    var session: URLSession = .shared

    /// Generate one image from `prompt`. `seed` is held constant across a strip's
    /// panels to keep the recurring character coherent.
    func generateImage(prompt: String, seed: Int) async throws -> Data {
        guard !apiKey.isEmpty else { throw FalError.noKey }

        var request = URLRequest(url: URL(string: "https://fal.run/\(model.rawValue)")!)
        request.httpMethod = "POST"
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90

        // Square panels read best in the BD page; "square_hd" is 1024².
        let body: [String: Any] = [
            "prompt": prompt,
            "image_size": "square_hd",
            "num_images": 1,
            "seed": seed,
            "enable_safety_checker": true,
            "output_format": "png",
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw FalError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw FalError.http(status: http.statusCode,
                                body: String(data: data, encoding: .utf8) ?? "")
        }

        let imageURL = try Self.firstImageURL(from: data)
        let (imgData, imgResponse) = try await session.data(from: imageURL)
        guard let imgHTTP = imgResponse as? HTTPURLResponse, (200..<300).contains(imgHTTP.statusCode),
              !imgData.isEmpty else {
            throw FalError.imageDownloadFailed
        }
        return imgData
    }

    /// Parse `{ "images": [{ "url": "..." }] }` and return the first image URL.
    /// Static + pure so it's unit-testable without the network.
    static func firstImageURL(from data: Data) throws -> URL {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FalError.badResponse
        }
        guard let images = json["images"] as? [[String: Any]] else { throw FalError.noImage }
        guard let first = images.first,
              let urlString = first["url"] as? String,
              let url = URL(string: urlString) else { throw FalError.noImage }
        return url
    }
}
