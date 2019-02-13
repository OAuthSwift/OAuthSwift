//
//  URLConvertible.swift
//  OAuthSwift
//
//  Created by Arman Arutyunov on 07/02/2019.
//  Copyright © 2019 Dongri Jin. All rights reserved.
//

import Foundation

/// Either a String representing URL or a URL itself
public protocol URLConvertible {
	var string: String { get }
	var url: URL? { get }
}

extension String: URLConvertible {
	public var string: String {
		return self
	}

	public var url: URL? {
		return URL(string: self)
	}
}

extension URL: URLConvertible {
	public var string: String {
		return absoluteString
	}

	public var url: URL? {
		return self
	}
}

extension URLConvertible {
    public var encodedURL: URL {
        return URL(string: self.string.urlEncoded)!
    }
}
