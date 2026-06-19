import Foundation

/// Утилита для форматирования номера телефона в маску +7 (XXX) XXX-XX-XX и получения "плоского" формата plain: +7XXXXXXXXXX.
struct PhoneFormatter {
    
    /// Публичный метод — принимает "сырой" ввод (с пробелами, скобками, 7/8 и т.п.) и возвращает:
    /// - formatted: строку для показа в UI (+7 (XXX) XXX-XX-XX)
    /// - plain: строку для API (+7XXXXXXXXXX).
    static func format(_ input: String) -> (formatted: String, plain: String) {
        // Оставить только цифры из ввода
        let digits = input.filter { $0.isNumber }
        
        var cleaned = digits
        
        // Если номер начинается с 8 или 7 — убирать, чтобы дальше работать с 10-ю цифрами
        if cleaned.hasPrefix("8") {
            cleaned.removeFirst()
        } else if cleaned.hasPrefix("7") {
            cleaned.removeFirst()
        }
        // Ограничить максимум 10-ю цифрами без кода страны
        if cleaned.count > 10 {
            cleaned = String(cleaned.prefix(10))
        }
        
        // Дальше используется общий метод форматирования уже "очищенных" цифр
        return formatCleaned(cleaned)
    }
    
    /// Форматирует уже очищенную строку 10 цифр в красивый формат +7 (XXX) XXX-XX-XX и plain: +7XXXXXXXXXX.
    static func formatCleaned(_ cleanedInput: String) -> (formatted: String, plain: String) {
        var cleaned = cleanedInput
        
        // Защита от лишних цифр (на всякий случай)
        if cleaned.count > 10 {
            cleaned = String(cleaned.prefix(10))
        }
        // Базовый префикс формата
        var result = "+7"
        if !cleaned.isEmpty {
            result += " "
        }
        
        //+7 (XXX)
        if !cleaned.isEmpty {
            result += "("
            let firstBlock = cleaned.prefix(3)
            result += firstBlock
            if cleaned.count >= 3 {
                result += ")"
            }
        }
        
        // +7 (ХХХ) ХХХ
        if cleaned.count > 3 {
            let start = cleaned.index(cleaned.startIndex, offsetBy: 3)
            let end = cleaned.index(start, offsetBy: min(3, cleaned.count - 3))
            let part = String(cleaned[start..<end])
            result += " " + part
        }
        
        // +7 (ХХХ) ХХХ-ХХ
        if cleaned.count > 6 {
            let start = cleaned.index(cleaned.startIndex, offsetBy: 6)
            let end = cleaned.index(start, offsetBy: min(2, cleaned.count - 6))
            let part = String(cleaned[start..<end])
            result += "-" + part
        }
        
        // +7 (ХХХ) ХХХ-ХХ-ХХ
        if cleaned.count > 8 {
            let start = cleaned.index(cleaned.startIndex, offsetBy: 8)
            let end = cleaned.index(start, offsetBy: min(2, cleaned.count - 8))
            let part = String(cleaned[start..<end])
            result += "-" + part
        }
        
        // plain-форма: +7ХХХХХХХХХХ
        let plain = "+7" + cleaned
        return (formatted: result, plain: plain)
    }
}
