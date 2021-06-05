//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { result in
			switch result {
			case let .success((data, httpResponse)):
				let decoder = JSONDecoder()
				guard httpResponse.statusCode == 200 else {
					completion(.failure(Error.invalidData))
					return
				}
				do {
					let feedImages = try decoder.decode(FeedImageResponse.self, from: data)
						.items
						.map { $0.feedImage }

					completion(.success(feedImages))
				} catch {
					completion(.failure(Error.invalidData))
				}
			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}

	private struct FeedImageResponse: Codable {
		let items: [FeedImageRepresentation]
	}

	private struct FeedImageRepresentation: Codable {
		let id: UUID
		let description: String?
		let location: String?
		let url: URL

		private enum CodingKeys: String, CodingKey {
			case id = "image_id"
			case description = "image_desc"
			case location = "image_loc"
			case url = "image_url"
		}

		public init(id: UUID, description: String?, location: String?, url: URL) {
			self.id = id
			self.description = description
			self.location = location
			self.url = url
		}

		var feedImage: FeedImage {
			FeedImage(id: id,
			          description: description,
			          location: location,
			          url: url)
		}
	}
}
