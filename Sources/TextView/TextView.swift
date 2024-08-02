import SwiftUI

public protocol TextViewProtocol {
    var height: CGFloat { get }
}

/// A SwiftUI TextView implementation that supports both scrolling and auto-sizing layouts
public struct TextView: View {

    @Environment(\.layoutDirection) private var layoutDirection

    @Binding private var text: NSAttributedString
    @Binding private var isEmpty: Bool

    @State private var calculatedHeight: CGFloat = 44

    private var onEditingChanged: ((TextViewProtocol) -> Void)?
    var shouldEditInRange: ((Range<String.Index>?, String) -> Bool)?
    private var onCommit: (() -> Void)?

    var placeholderView: AnyView?
    var foregroundColor: UIColor = .label
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var multilineTextAlignment: TextAlignment = .leading
    var font: UIFont = .preferredFont(forTextStyle: .body)
    var returnKeyType: UIReturnKeyType?
    var clearsOnInsertion: Bool = false
    var shouldDisplayAccessoryView: Bool = false
    var autocorrection: UITextAutocorrectionType = .default
    var spellCheck: UITextSpellCheckingType = .default
    var truncationMode: NSLineBreakMode = .byTruncatingTail
    var isEditable: Bool = true
    var isSelectable: Bool = true
    var isScrollingEnabled: Bool = false
    var enablesReturnKeyAutomatically: Bool?
    var autoDetectionTypes: UIDataDetectorTypes = []
    var allowRichText: Bool
    var alignment: Alignment = .center
    var maxNumberOfCharacters: Int  // Maximum character limit

    /// Makes a new TextView with the specified configuration
    /// - Parameters:
    ///   - text: A binding to the text
    ///   - shouldEditInRange: A closure that's called before an edit it applied, allowing the consumer to prevent the change
    ///   - onEditingChanged: A closure that's called after an edit has been applied
    ///   - onCommit: If this is provided, the field will automatically lose focus when the return key is pressed
    public init(_ text: Binding<String>,
                lineSpacing: CGFloat = 0,
                shouldEditInRange: ((Range<String.Index>?, String) -> Bool)? = nil,
                onEditingChanged: ((TextViewProtocol) -> Void)? = nil,
                onCommit: (() -> Void)? = nil,
                maxNumberOfCharacters: Int) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        let attributes = [NSAttributedString.Key.paragraphStyle : style]

        _text = Binding(
            get: { NSAttributedString(string: text.wrappedValue, attributes: attributes) },
            set: { text.wrappedValue = $0.string }
        )

        _isEmpty = Binding(
            get: { text.wrappedValue.isEmpty },
            set: { _ in }
        )

        self.onCommit = onCommit
        self.shouldEditInRange = shouldEditInRange
        self.onEditingChanged = onEditingChanged
        self.maxNumberOfCharacters = maxNumberOfCharacters

        allowRichText = false
    }

    /// Makes a new TextView that supports `NSAttributedString`
    /// - Parameters:
    ///   - text: A binding to the attributed text
    ///   - onEditingChanged: A closure that's called after an edit has been applied
    ///   - onCommit: If this is provided, the field will automatically lose focus when the return key is pressed
    public init(_ text: Binding<NSAttributedString>,
                onEditingChanged: ((TextViewProtocol) -> Void)? = nil,
                shouldEditInRange: ((Range<String.Index>?, String) -> Bool)? = nil,
                onCommit: (() -> Void)? = nil,
                maxNumberOfCharacters: Int = 500) {
        _text = text
        _isEmpty = Binding(
            get: { text.wrappedValue.string.isEmpty },
            set: { _ in }
        )

        self.onCommit = onCommit
        self.onEditingChanged = onEditingChanged
        self.shouldEditInRange = shouldEditInRange
        self.maxNumberOfCharacters = maxNumberOfCharacters

        allowRichText = true
    }

    public var body: some View {
        Representable(
            text: $text,
            calculatedHeight: $calculatedHeight,
            foregroundColor: foregroundColor,
            autocapitalization: autocapitalization,
            multilineTextAlignment: multilineTextAlignment,
            font: font,
            returnKeyType: returnKeyType,
            clearsOnInsertion: clearsOnInsertion,
            shouldDisplayAccessoryView: shouldDisplayAccessoryView,
            autocorrection: autocorrection,
            spellCheck: spellCheck,
            truncationMode: truncationMode,
            isEditable: isEditable,
            isSelectable: isSelectable,
            isScrollingEnabled: isScrollingEnabled,
            enablesReturnKeyAutomatically: enablesReturnKeyAutomatically,
            autoDetectionTypes: autoDetectionTypes,
            allowsRichText: allowRichText, 
            maxNumberOfCharacters: maxNumberOfCharacters,
            onEditingChanged: onEditingChanged,
            shouldEditInRange: shouldEditInRange,
            onCommit: onCommit
        )
        .frame(
            minHeight: isScrollingEnabled ? 0 : calculatedHeight,
            maxHeight: isScrollingEnabled ? .infinity : calculatedHeight,
            alignment: alignment
        )
        .background(
            placeholderView?
                .foregroundColor(Color(.placeholderText))
                .multilineTextAlignment(multilineTextAlignment)
                .font(Font(font))
                .padding(.horizontal, isScrollingEnabled ? 5 : 0)
                .padding(.vertical, isScrollingEnabled ? 8 : 0)
                .opacity(isEmpty ? 1 : 0),
            alignment: .topLeading
        )
    }

}

final class UIKitTextView: UITextView {

    override var keyCommands: [UIKeyCommand]? {
        return (super.keyCommands ?? []) + [
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escape(_:)))
        ]
    }

    @objc private func escape(_ sender: Any) {
        resignFirstResponder()
    }

}

struct RoundedTextView: View {
    @State private var text: NSAttributedString = .init()

    var body: some View {
        VStack(alignment: .leading) {
            TextView($text)
                .padding(.leading, 25)

            GeometryReader { _ in
                TextView($text)
                    .placeholder("Enter some text")
                    .padding(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(lineWidth: 1)
                            .foregroundColor(Color(.placeholderText))
                    )
                    .padding()
            }
            .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))

            Button {
                text = NSAttributedString(string: "This is interesting", attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .headline)
                ])
            } label: {
                Spacer()
                Text("Interesting?")
                Spacer()
            }
            .padding()
        }
    }
}

struct TextView_Previews: PreviewProvider {
    static var previews: some View {
        RoundedTextView()
    }
}
