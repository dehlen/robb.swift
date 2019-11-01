import Foundation
import HTML

struct AtomFeed: Page {
    static let defaultLayout: Layout = .empty

    let baseURL: URL

    let contentType = "application/xml"

    let dateFormatter = ISO8601DateFormatter()

    let markdownFilter = MarkdownFilter()

    let pathComponents = [ "atom.xml" ]

    let posts: [Post]

    let title = "robb.is"

    func content() -> Node {
        feed(xmlns: "http://www.w3.org/2005/Atom") {
            author {
                name {
                    "Robert Böhnke"
                }
            }
            title {
                self.title
            }
            id {
                "http://robb.is/"
            }
            updated {
                posts.last!.date
            }
            link(href: baseURL.appendingPathComponent(path).absoluteString, rel: "self")

            posts
                .reversed()
                .map { post in
                    entry {
                        title {
                            post.title
                        }
                        id {
                            baseURL
                                .appendingPathComponent(post.path)
                                .absoluteString
                        }
                        link(href: post.link ?? baseURL.appendingPathComponent(post.path).absoluteString, rel: "alternate")
                        updated {
                            post.date
                        }

                        if post.description != nil {
                            summary {
                                post.description!
                            }
                        }

                        content(type: "html") {
                            let unfiltered = post.content()

                            let filtered = markdownFilter.apply(node: unfiltered)

                            return String(describing: filtered).addingXMLEncoding()
                        }
                    }
                }
        }
    }
}

extension AtomFeed {
    private func feed(xmlns: String, @NodeBuilder children: () -> NodeConvertible) -> Node {
        .element("feed", [ "xmlns": xmlns ], children().asNode())
    }

    private func author(@NodeBuilder children: () -> NodeConvertible) -> Node {
        .element("author", [:], children().asNode())
    }

    private func name(children: () -> String) -> Node {
        .element("name", [:], children().asNode())
    }

    private func title(type: String = "text", children: () -> String) -> Node {
        .element("title", [ "type": type ], %children().asNode()%)
    }

    private func id(children: () -> String) -> Node {
        .element("id", [:], %children().asNode()%)
    }

    private func updated(day: () -> Day) -> Node {
        let date = Calendar(identifier: .gregorian).date(from: day().dateComponents)!

        return .element("updated", [:], %.text(dateFormatter.string(from: date))%)
    }

    private func entry(@NodeBuilder children: () -> NodeConvertible) -> Node {
        .element("entry", [:], children().asNode())
    }

    private func link(href: String, rel: String) -> Node {
        .element("link", [ "href": href, "rel": rel ], [])
    }

    private func summary(type: String = "text", children: () -> String) -> Node {
        .element("summary", [ "type": type ], children().asNode())
    }

    private func content(type: String = "text", children: () -> String) -> Node {
        .element("content", [ "type": type ], children().asNode())
    }
}

private extension String {
    func addingXMLEncoding() -> String {
        trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
