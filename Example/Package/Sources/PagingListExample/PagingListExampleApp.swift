import SwiftUI

public struct PagingListExampleApp: View {

    public init() {}
    
    public var body: some View {
        PagingListScreen(dependency: .init(api: .real))
    }
}
