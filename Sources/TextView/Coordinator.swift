import SwiftUI

extension TextView.Representable {
    final class Coordinator: NSObject, UITextViewDelegate {

        internal let textView: UIKitTextView

        private var originalText: NSAttributedString = .init()
        private var text: Binding<NSAttributedString>
        private var calculatedHeight: Binding<CGFloat>

        var onCommit: (() -> Void)?
        var onEditingChanged: ((TextViewProtocol) -> Void)?
        var shouldEditInRange: ((Range<String.Index>?, String) -> Bool)?

        init(text: Binding<NSAttributedString>,
             calculatedHeight: Binding<CGFloat>,
             shouldEditInRange: ((Range<String.Index>?, String) -> Bool)?,
             onEditingChanged: ((TextViewProtocol) -> Void)?,
             onCommit: (() -> Void)?
        ) {
            textView = UIKitTextView()
            textView.backgroundColor = .clear
            textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            self.text = text
            self.calculatedHeight = calculatedHeight
            self.shouldEditInRange = shouldEditInRange
            self.onEditingChanged = onEditingChanged
            self.onCommit = onCommit

            super.init()
            textView.delegate = self
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            originalText = text.wrappedValue
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = NSAttributedString(attributedString: textView.attributedText)
            recalculateHeight()
            onEditingChanged?(self)
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if onCommit != nil, text == "\n" {
                onCommit?()
                originalText = NSAttributedString(attributedString: textView.attributedText)
                textView.resignFirstResponder()
                return false
            }

            if let shouldEditInRange = shouldEditInRange {
                return shouldEditInRange(Range(range, in: text), text)
            }

            return true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            // this check is to ensure we always commit text when we're not using a closure
            if onCommit != nil {
                text.wrappedValue = originalText
            }
        }

    }

}

extension TextView.Representable.Coordinator: TextViewProtocol {

    public var height: CGFloat {
        return calculatedHeight.wrappedValue
    }

    func update(representable: TextView.Representable) {
        let range = textView.selectedRange // Save cursor (accidentally moved to end by update)
        textView.attributedText = representable.text
        textView.selectedRange = range // Restore cursor        
        textView.font = representable.font
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = representable.foregroundColor
        textView.autocapitalizationType = representable.autocapitalization
        textView.autocorrectionType = representable.autocorrection
        textView.spellCheckingType = representable.spellCheck
        textView.isEditable = representable.isEditable
        textView.isSelectable = representable.isSelectable
        textView.isScrollEnabled = representable.isScrollingEnabled
        textView.dataDetectorTypes = representable.autoDetectionTypes
        textView.allowsEditingTextAttributes = representable.allowsRichText

        switch representable.multilineTextAlignment {
        case .leading:
            textView.textAlignment = textView.traitCollection.layoutDirection ~= .leftToRight ? .left : .right
        case .trailing:
            textView.textAlignment = textView.traitCollection.layoutDirection ~= .leftToRight ? .right : .left
        case .center:
            textView.textAlignment = .center
        }

        if let value = representable.enablesReturnKeyAutomatically {
            textView.enablesReturnKeyAutomatically = value
        } else {
            textView.enablesReturnKeyAutomatically = onCommit == nil ? false : true
        }

        if let returnKeyType = representable.returnKeyType {
            textView.returnKeyType = returnKeyType
        } else {
            textView.returnKeyType = onCommit == nil ? .default : .done
        }

        if !representable.isScrollingEnabled {
            textView.textContainer.lineFragmentPadding = 0
            textView.textContainerInset = .zero
        }

        recalculateHeight()
        textView.setNeedsDisplay()
    }

    func recalculateHeight() {
        let newSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
        guard calculatedHeight.wrappedValue != newSize.height else { return }

        DispatchQueue.main.async { // call in next render cycle.
            self.calculatedHeight.wrappedValue = newSize.height
        }
    }

}
