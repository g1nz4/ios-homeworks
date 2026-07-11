import UIKit

/// Результат форматирования текста с "Показать ещё" / "Свернуть".
struct CollapsedTextResult {
    /// Итоговый атрибутированный текст.
    let attributedText: NSAttributedString
    /// Ограничение по количеству строк для UILabel.
    let numberOfLines: Int
    /// Диапазон кликабельного "Показать ещё"/"Свернуть" в attributedText.
    let moreRange: NSRange?
}

/// Отвечает за сворачивание/разворачивание текста и добавление хвостов "Показать ещё" / "Свернуть".
enum CollapsedTextFormatter {
    
    /// Собирает итоговый текст с учётом состояния (свернут / развёрнут).
    static func make(
        fullText: String,
        isExpanded: Bool,
        labelFont: UIFont,
        labelTextColor: UIColor,
        actionTextColor: UIColor,
        maxCollapsedLines: Int = 4,
        labelWidth: CGFloat
    ) -> CollapsedTextResult? {
        let trimmed = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        if isExpanded {
            return makeExpanded(
                text: trimmed,
                font: labelFont,
                textColor: labelTextColor,
                actionColor: actionTextColor
            )
        } else {
            return makeCollapsed(
                text: trimmed,
                font: labelFont,
                textColor: labelTextColor,
                actionColor: actionTextColor,
                maxLines: maxCollapsedLines,
                width: labelWidth
            )
        }
    }
    
    private static func makeExpanded(
        text: String,
        font: UIFont,
        textColor: UIColor,
        actionColor: UIColor
    ) -> CollapsedTextResult {
        let base = NSMutableAttributedString(
            string: text + " ",
            attributes: [
                .font: font,
                .foregroundColor: textColor
            ]
        )
        
        let moreText = "Свернуть"
        let moreAttr = NSAttributedString(
            string: moreText,
            attributes: [
                .font: font,
                .foregroundColor: actionColor
            ]
        )
        
        let range = NSRange(location: base.length, length: moreText.count)
        base.append(moreAttr)
        
        return CollapsedTextResult(
            attributedText: base,
            numberOfLines: 0,
            moreRange: range
        )
    }
    
    private static func makeCollapsed(
        text: String,
        font: UIFont,
        textColor: UIColor,
        actionColor: UIColor,
        maxLines: Int,
        width: CGFloat
    ) -> CollapsedTextResult {
        let maxLinesFixed = 4
        
        let fullAttr = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: textColor
            ]
        )
        
        let fitsCheck = truncatedAttributedString(
            full: fullAttr,
            trailing: "",
            font: font,
            width: width,
            maxLines: maxLinesFixed
        )
        if fitsCheck.fits {
            return CollapsedTextResult(
                attributedText: fullAttr,
                numberOfLines: 0,
                moreRange: nil
            )
        }
        
        let moreTextPlain = " Показать ещё"
        let trailingPlain = "…" + moreTextPlain
        
        let truncated = truncatedAttributedString(
            full: fullAttr,
            trailing: trailingPlain,
            font: font,
            width: width,
            maxLines: maxLinesFixed
        )
        
        let result = NSMutableAttributedString(attributedString: truncated.text)
        
        let dotsAttr = NSAttributedString(
            string: "…",
            attributes: [
                .font: font,
                .foregroundColor: textColor
            ]
        )
        result.append(dotsAttr)
        
        let moreAttr = NSAttributedString(
            string: moreTextPlain,
            attributes: [
                .font: font,
                .foregroundColor: actionColor
            ]
        )
        let moreRange = NSRange(location: result.length, length: moreTextPlain.count)
        result.append(moreAttr)
        
        return CollapsedTextResult(
            attributedText: result,
            numberOfLines: maxLinesFixed,
            moreRange: moreRange
        )
    }
    
    /// Подбирает максимальный префикс строки так, чтобы `префикс + trailing` помещались в maxLines строк.
    private static func truncatedAttributedString(
        full: NSAttributedString,
        trailing: String,
        font: UIFont,
        width: CGFloat,
        maxLines: Int
    ) -> (text: NSAttributedString, fits: Bool) {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = font
        label.attributedText = full
        
        let fullSize = label.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        let lineHeight = font.lineHeight
        let fullLines = Int(ceil(fullSize.height / lineHeight))
        if fullLines <= maxLines {
            return (full, true)
        }
        
        var low = 0
        var high = full.string.count
        var best = full
        
        while low < high {
            let mid = (low + high) / 2
            let subString = String(full.string.prefix(mid))
            
            let testAttr = NSAttributedString(
                string: subString + trailing,
                attributes: [.font: font]
            )
            label.attributedText = testAttr
            
            let size = label.sizeThatFits(
                CGSize(width: width, height: .greatestFiniteMagnitude)
            )
            let lines = Int(ceil(size.height / lineHeight))
            
            if lines > maxLines {
                high = mid - 1
            } else {
                best = NSAttributedString(string: subString, attributes: [.font: font])
                low = mid + 1
            }
        }
        
        return (best, false)
    }
}
    
